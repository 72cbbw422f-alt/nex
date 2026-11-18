#!/usr/bin/env python3
"""Inspect a remote ZIP central directory and selected small metadata members.

All network reads use bounded HTTP Range requests. This tool never falls back
to a full download; a server that ignores Range is rejected.
"""
from __future__ import annotations

import argparse
import plistlib
import re
import struct
import sys
import urllib.error
import urllib.request
import zlib
from dataclasses import dataclass

DEFAULT_URL = (
    "https://download.videolan.org/cocoapods/unstable/"
    "VLCKit-4.0-20261109-1916.zip"
)
MAX_TAIL_BYTES = 65_557
MAX_CENTRAL_DIRECTORY_BYTES = 32 * 1024 * 1024
MAX_MEMBER_COMPRESSED_BYTES = 1024 * 1024
MAX_MEMBER_UNCOMPRESSED_BYTES = 4 * 1024 * 1024
MAX_HEADER_EXTRA_BYTES = 65_535
USER_AGENT = "NEXUS-remote-zip-audit/1.1"


class InspectionError(RuntimeError):
    pass


@dataclass(frozen=True)
class ZipEntry:
    name: str
    flags: int
    method: int
    compressed_size: int
    uncompressed_size: int
    local_header_offset: int


def request_range(url: str, start: int | None, end: int | None, suffix: int | None = None) -> tuple[bytes, int, int, int]:
    if suffix is not None:
        range_value = f"bytes=-{suffix}"
        expected_limit = suffix
    else:
        if start is None or end is None or start < 0 or end < start:
            raise InspectionError("Invalid byte range")
        range_value = f"bytes={start}-{end}"
        expected_limit = end - start + 1

    request = urllib.request.Request(
        url,
        headers={"Range": range_value, "Accept-Encoding": "identity", "User-Agent": USER_AGENT},
        method="GET",
    )
    try:
        response = urllib.request.urlopen(request, timeout=30)
    except urllib.error.HTTPError as error:
        error.read(1024)
        raise InspectionError(f"Range request failed: HTTP {error.code}") from error

    with response:
        status = response.status
        content_range = response.headers.get("Content-Range", "")
        match = re.fullmatch(r"bytes (\d+)-(\d+)/(\d+)", content_range)
        body = response.read(expected_limit + 1)
        if status != 206:
            raise InspectionError(f"Server did not honor Range (HTTP {status}); stopped without full download")
        if not match:
            raise InspectionError("Missing or invalid Content-Range on HTTP 206")
        actual_start, actual_end, total = map(int, match.groups())
        if len(body) > expected_limit:
            raise InspectionError("Server returned more bytes than requested; response closed")
        if len(body) != actual_end - actual_start + 1:
            raise InspectionError("Body length does not match Content-Range")
        if suffix is not None:
            if actual_end != total - 1 or actual_start != total - len(body) or len(body) > suffix:
                raise InspectionError("Unexpected suffix range response")
        elif actual_start != start or actual_end != end:
            raise InspectionError("Server returned a different byte range")
        return body, actual_start, actual_end, total


def find_eocd(tail: bytes, absolute_start: int) -> tuple[int, int, int]:
    position = tail.rfind(b"PK\x05\x06")
    if position < 0 or len(tail) - position < 22:
        raise InspectionError("ZIP end-of-central-directory record not found")
    fields = struct.unpack_from("<4s4H2IH", tail, position)
    _, disk, central_disk, entries_on_disk, entries_total, cd_size, cd_offset, comment_len = fields
    if position + 22 + comment_len != len(tail):
        raise InspectionError("EOCD comment length is inconsistent")
    if disk != 0 or central_disk != 0 or entries_on_disk != entries_total:
        raise InspectionError("Multi-disk ZIP archives are not supported")
    if 0xFFFF in (entries_total,) or 0xFFFFFFFF in (cd_size, cd_offset):
        raise InspectionError("ZIP64 archive detected; refusing unsupported metadata layout")
    return cd_offset, cd_size, entries_total


def parse_central_directory_entries(data: bytes, expected_entries: int) -> list[ZipEntry]:
    entries: list[ZipEntry] = []
    offset = 0
    for _ in range(expected_entries):
        if offset + 46 > len(data) or data[offset:offset + 4] != b"PK\x01\x02":
            raise InspectionError("Invalid central-directory entry")
        fields = struct.unpack_from("<4s6H3I5H2I", data, offset)
        flags, method = fields[3], fields[4]
        compressed_size, uncompressed_size = fields[8], fields[9]
        name_len, extra_len, comment_len = fields[10], fields[11], fields[12]
        local_offset = fields[16]
        end = offset + 46 + name_len + extra_len + comment_len
        if end > len(data):
            raise InspectionError("Central-directory entry exceeds fetched range")
        raw_name = data[offset + 46:offset + 46 + name_len]
        try:
            name = raw_name.decode("utf-8")
        except UnicodeDecodeError:
            name = raw_name.decode("cp437")
        if 0xFFFFFFFF in (compressed_size, uncompressed_size, local_offset):
            raise InspectionError(f"ZIP64 member metadata is not supported: {name}")
        entries.append(ZipEntry(name, flags, method, compressed_size, uncompressed_size, local_offset))
        offset = end
    if offset != len(data):
        raise InspectionError("Central-directory size does not match parsed entries")
    return entries


def parse_central_directory(data: bytes, expected_entries: int) -> list[str]:
    return [entry.name for entry in parse_central_directory_entries(data, expected_entries)]


def fetch_member(url: str, entry: ZipEntry, archive_size: int) -> bytes:
    if entry.flags & 0x1:
        raise InspectionError(f"Encrypted ZIP member is not supported: {entry.name}")
    if entry.compressed_size > MAX_MEMBER_COMPRESSED_BYTES:
        raise InspectionError(f"Compressed metadata member exceeds {MAX_MEMBER_COMPRESSED_BYTES} byte limit: {entry.name}")
    if entry.uncompressed_size > MAX_MEMBER_UNCOMPRESSED_BYTES:
        raise InspectionError(f"Uncompressed metadata member exceeds {MAX_MEMBER_UNCOMPRESSED_BYTES} byte limit: {entry.name}")

    header, _, _, total = request_range(url, entry.local_header_offset, entry.local_header_offset + 29)
    if total != archive_size or header[:4] != b"PK\x03\x04":
        raise InspectionError(f"Invalid local ZIP header: {entry.name}")
    fields = struct.unpack_from("<4s5H3I2H", header)
    local_flags, local_method = fields[2], fields[3]
    name_len, extra_len = fields[9], fields[10]
    if local_flags != entry.flags or local_method != entry.method:
        raise InspectionError(f"Local/central ZIP header mismatch: {entry.name}")
    if name_len > 65_535 or extra_len > MAX_HEADER_EXTRA_BYTES:
        raise InspectionError(f"Invalid local ZIP header lengths: {entry.name}")
    header_end = entry.local_header_offset + 30 + name_len + extra_len
    if header_end + entry.compressed_size > archive_size:
        raise InspectionError(f"ZIP member data lies outside archive: {entry.name}")
    variable = b""
    if name_len + extra_len:
        variable, _, _, total = request_range(url, entry.local_header_offset + 30, header_end - 1)
        if total != archive_size:
            raise InspectionError("Archive size changed during member inspection")
    local_name = variable[:name_len]
    try:
        decoded_local_name = local_name.decode("utf-8")
    except UnicodeDecodeError:
        decoded_local_name = local_name.decode("cp437")
    if decoded_local_name != entry.name:
        raise InspectionError(f"Local/central filename mismatch: {entry.name}")

    if entry.compressed_size == 0:
        compressed = b""
    else:
        compressed, _, _, total = request_range(url, header_end, header_end + entry.compressed_size - 1)
        if total != archive_size:
            raise InspectionError("Archive size changed during member data read")
    if entry.method == 0:
        payload = compressed
    elif entry.method == 8:
        try:
            payload = zlib.decompress(compressed, -15)
        except zlib.error as error:
            raise InspectionError(f"Invalid deflate stream: {entry.name}") from error
    else:
        raise InspectionError(f"Unsupported ZIP compression method {entry.method}: {entry.name}")
    if len(payload) != entry.uncompressed_size:
        raise InspectionError(f"Uncompressed member size mismatch: {entry.name}")
    return payload


def inspect(url: str) -> tuple[list[ZipEntry], dict[str, object]]:
    tail, tail_start, _, total = request_range(url, None, None, MAX_TAIL_BYTES)
    cd_offset, cd_size, entry_count = find_eocd(tail, tail_start)
    if cd_size > MAX_CENTRAL_DIRECTORY_BYTES:
        raise InspectionError(f"Central directory is too large ({cd_size} bytes); limit is {MAX_CENTRAL_DIRECTORY_BYTES}")
    if cd_offset + cd_size > total:
        raise InspectionError("Central-directory range lies outside the archive")
    if cd_size == 0:
        return [], {}
    central, _, _, second_total = request_range(url, cd_offset, cd_offset + cd_size - 1)
    if second_total != total:
        raise InspectionError("Archive size changed between range requests")
    entries = parse_central_directory_entries(central, entry_count)

    plist_entries = [entry for entry in entries if entry.name.endswith(".xcframework/Info.plist")]
    metadata: dict[str, object] = {}
    for entry in plist_entries:
        payload = fetch_member(url, entry, total)
        try:
            parsed = plistlib.loads(payload)
        except Exception as error:
            raise InspectionError(f"Could not parse XCFramework Info.plist ({entry.name}): {error}") from error
        if not isinstance(parsed, dict):
            raise InspectionError(f"XCFramework Info.plist is not a dictionary: {entry.name}")
        metadata[entry.name] = parsed
    return entries, metadata


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DEFAULT_URL, help="Remote ZIP URL (default: pinned VideoLAN VLCKit archive)")
    args = parser.parse_args()
    try:
        entries, metadata = inspect(args.url)
    except InspectionError as error:
        print(f"STOP: {error}", file=sys.stderr)
        return 2

    frameworks = [name for name in (entry.name for entry in entries) if ".xcframework/" in name or name.endswith(".xcframework/")]
    print(f"Archive central directory inspected; {len(entries)} entries indexed.")
    print("XCFramework-related paths:")
    for name in frameworks:
        print(name)
    if not frameworks:
        print("No XCFramework paths found in the ZIP central directory.")
    for path, plist in metadata.items():
        print(f"\n{path}")
        print(f"  PackageType: {plist.get('CFBundlePackageType')}")
        print(f"  AvailableLibraries:")
        for library in plist.get("AvailableLibraries", []):
            if isinstance(library, dict):
                print(
                    "  - "
                    f"identifier={library.get('LibraryIdentifier')} "
                    f"platform={library.get('SupportedPlatform')} "
                    f"variant={library.get('SupportedPlatformVariant')} "
                    f"architectures={','.join(library.get('SupportedArchitectures', []))}"
                )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
