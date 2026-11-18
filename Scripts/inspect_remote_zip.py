#!/usr/bin/env python3
"""Inspect a remote ZIP central directory using strictly bounded HTTP Range reads.

This tool never falls back to a full download. A server that ignores Range and
returns HTTP 200 is rejected; the response is read only up to the configured
cap before the connection is closed.
"""
from __future__ import annotations

import argparse
import re
import struct
import sys
import urllib.error
import urllib.request

DEFAULT_URL = (
    "https://download.videolan.org/cocoapods/unstable/"
    "VLCKit-4.0-20261109-1916.zip"
)
MAX_TAIL_BYTES = 65_557  # ZIP comment (65,535) + EOCD (22)
MAX_CENTRAL_DIRECTORY_BYTES = 32 * 1024 * 1024
USER_AGENT = "NEXUS-remote-zip-audit/1.0"


class InspectionError(RuntimeError):
    pass


def request_range(url: str, start: int | None, end: int | None, suffix: int | None = None) -> tuple[bytes, int, int, int]:
    if suffix is not None:
        range_value = f"bytes=-{suffix}"
    else:
        if start is None or end is None or start < 0 or end < start:
            raise InspectionError("Invalid byte range")
        range_value = f"bytes={start}-{end}"

    request = urllib.request.Request(
        url,
        headers={"Range": range_value, "Accept-Encoding": "identity", "User-Agent": USER_AGENT},
        method="GET",
    )
    try:
        response = urllib.request.urlopen(request, timeout=30)
    except urllib.error.HTTPError as error:
        # Read only a tiny diagnostic amount; never consume an unexpected body.
        error.read(1024)
        raise InspectionError(f"Range request failed: HTTP {error.code}") from error

    with response:
        status = response.status
        content_range = response.headers.get("Content-Range", "")
        match = re.fullmatch(r"bytes (\d+)-(\d+)/(\d+)", content_range)
        expected_limit = suffix if suffix is not None else end - start + 1
        body = response.read(expected_limit + 1)

        # A 200 response means Range was ignored. Close immediately; do not
        # retry without Range or save any part as if it were a valid response.
        if status != 206:
            raise InspectionError(f"Server did not honor Range (HTTP {status}); stopped without full download")
        if not match:
            raise InspectionError("Missing or invalid Content-Range on HTTP 206")
        actual_start, actual_end, total = map(int, match.groups())
        if len(body) > expected_limit:
            raise InspectionError("Server returned more bytes than the requested range; response closed")
        if len(body) != actual_end - actual_start + 1:
            raise InspectionError("Body length does not match Content-Range")
        if suffix is not None:
            if actual_end != total - 1 or actual_start != total - len(body) or len(body) > suffix:
                raise InspectionError("Unexpected suffix range response")
        elif actual_start != start or actual_end != end:
            raise InspectionError("Server returned a different byte range")
        return body, actual_start, actual_end, total


def find_eocd(tail: bytes, absolute_start: int) -> tuple[int, int, int]:
    signature = b"PK\x05\x06"
    position = tail.rfind(signature)
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


def parse_central_directory(data: bytes, expected_entries: int) -> list[str]:
    entries: list[str] = []
    offset = 0
    for _ in range(expected_entries):
        if offset + 46 > len(data) or data[offset:offset + 4] != b"PK\x01\x02":
            raise InspectionError("Invalid central-directory entry")
        fields = struct.unpack_from("<4s6H3I5H2I", data, offset)
        name_len, extra_len, comment_len = fields[10], fields[11], fields[12]
        end = offset + 46 + name_len + extra_len + comment_len
        if end > len(data):
            raise InspectionError("Central-directory entry exceeds fetched range")
        raw_name = data[offset + 46:offset + 46 + name_len]
        try:
            name = raw_name.decode("utf-8")
        except UnicodeDecodeError:
            name = raw_name.decode("cp437")
        entries.append(name)
        offset = end
    if offset != len(data):
        raise InspectionError("Central-directory size does not match parsed entries")
    return entries


def inspect(url: str) -> list[str]:
    tail, tail_start, _, total = request_range(url, None, None, MAX_TAIL_BYTES)
    cd_offset, cd_size, entry_count = find_eocd(tail, tail_start)
    if cd_size > MAX_CENTRAL_DIRECTORY_BYTES:
        raise InspectionError(f"Central directory is too large ({cd_size} bytes); limit is {MAX_CENTRAL_DIRECTORY_BYTES}")
    if cd_offset + cd_size > total:
        raise InspectionError("Central-directory range lies outside the archive")
    if cd_size == 0:
        return []
    central, _, _, second_total = request_range(url, cd_offset, cd_offset + cd_size - 1)
    if second_total != total:
        raise InspectionError("Archive size changed between range requests")
    return parse_central_directory(central, entry_count)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url", default=DEFAULT_URL, help="Remote ZIP URL (default: pinned VideoLAN VLCKit archive)")
    args = parser.parse_args()
    try:
        entries = inspect(args.url)
    except InspectionError as error:
        print(f"STOP: {error}", file=sys.stderr)
        return 2

    frameworks = [name for name in entries if ".xcframework/" in name or name.endswith(".xcframework/")]
    print(f"Archive central directory inspected; {len(entries)} entries indexed.")
    print("XCFramework-related paths:")
    for name in frameworks:
        print(name)
    if not frameworks:
        print("No XCFramework paths found in the ZIP central directory.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
