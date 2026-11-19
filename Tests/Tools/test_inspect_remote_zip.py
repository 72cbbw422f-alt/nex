import io
import plistlib
import struct
import sys
import unittest
import zipfile
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "Scripts"))
from inspect_remote_zip import (
    InspectionError,
    fetch_member,
    find_eocd,
    parse_central_directory,
    parse_central_directory_entries,
    parse_macho_architectures,
    fetch_member_prefix,
    inspect_macho_binaries,
)


class RemoteZipInspectorTests(unittest.TestCase):
    def make_archive(self):
        output = io.BytesIO()
        metadata = {
            "CFBundlePackageType": "XFWK",
            "AvailableLibraries": [
                {
                    "LibraryIdentifier": "ios-arm64",
                    "SupportedPlatform": "ios",
                    "SupportedArchitectures": ["arm64"],
                },
                {
                    "LibraryIdentifier": "tvos-arm64_x86_64-simulator",
                    "SupportedPlatform": "tvos",
                    "SupportedPlatformVariant": "simulator",
                    "SupportedArchitectures": ["arm64", "x86_64"],
                },
            ],
        }
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("VLCKit.xcframework/Info.plist", plistlib.dumps(metadata))
            archive.writestr("VLCKit.xcframework/ios-arm64/VLCKit.framework/VLCKit", b"binary")
            archive.writestr("VLCKit.xcframework/tvos-arm64/VLCKit.framework/VLCKit", b"binary")
        return output.getvalue()

    def test_reads_zip_central_directory(self):
        payload = self.make_archive()
        tail_size = min(len(payload), 65557)
        tail_start = len(payload) - tail_size
        tail = payload[tail_start:]
        offset, size, count = find_eocd(tail, tail_start)
        entries = parse_central_directory(payload[offset:offset + size], count)
        self.assertIn("VLCKit.xcframework/Info.plist", entries)
        self.assertTrue(any("ios-arm64" in name for name in entries))
        self.assertTrue(any("tvos-arm64" in name for name in entries))

    def test_parses_xcframework_directory_metadata(self):
        payload = self.make_archive()
        tail = payload[-min(len(payload), 65557):]
        offset, size, count = find_eocd(tail, len(payload) - len(tail))
        entries = parse_central_directory_entries(payload[offset:offset + size], count)
        plist_entry = next(item for item in entries if item.name.endswith(".xcframework/Info.plist"))
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            metadata = plistlib.loads(archive.read(plist_entry.name))
        self.assertEqual(metadata["CFBundlePackageType"], "XFWK")
        self.assertEqual(metadata["AvailableLibraries"][0]["SupportedPlatform"], "ios")
        self.assertEqual(metadata["AvailableLibraries"][1]["SupportedPlatformVariant"], "simulator")

    def test_fetches_deflated_member_with_bounded_ranges(self):
        payload = self.make_archive()
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            info = archive.getinfo("VLCKit.xcframework/Info.plist")
        with zipfile.ZipFile(io.BytesIO(payload)) as archive:
            central_start = payload.find(b"PK\\x01\\x02" + b"")  # central header is used only to obtain test metadata
        tail = payload[-min(len(payload), 65557):]
        cd_offset, cd_size, count = find_eocd(tail, len(payload) - len(tail))
        entries = parse_central_directory_entries(payload[cd_offset:cd_offset + cd_size], count)
        entry = next(item for item in entries if item.name == info.filename)

        def fake_range(_url, start, end, suffix=None):
            if suffix is not None:
                body = payload[-suffix:]
                return body, len(payload) - len(body), len(payload) - 1, len(payload)
            return payload[start:end + 1], start, end, len(payload)

        with patch("inspect_remote_zip.request_range", side_effect=fake_range):
            result = fetch_member("https://example.invalid/archive.zip", entry, len(payload))
        self.assertEqual(plistlib.loads(result)["CFBundlePackageType"], "XFWK")


    def test_fetches_and_parses_stored_macho_prefix(self):
        payload = io.BytesIO()
        macho = struct.pack("<Iii", 0xFEEDFACF, 0x0100000C, 0) + b"payload"
        with zipfile.ZipFile(payload, "w", compression=zipfile.ZIP_STORED) as archive:
            archive.writestr("VLCKit.xcframework/ios-arm64/VLCKit.framework/VLCKit", macho)
        raw = payload.getvalue()
        with zipfile.ZipFile(io.BytesIO(raw)) as archive:
            info = archive.getinfo("VLCKit.xcframework/ios-arm64/VLCKit.framework/VLCKit")
        tail = raw[-min(len(raw), 65557):]
        offset, size, count = find_eocd(tail, len(raw) - len(tail))
        entries = parse_central_directory_entries(raw[offset:offset + size], count)
        entry = next(item for item in entries if item.name == info.filename)

        def fake_range(_url, start, end, suffix=None):
            if suffix is not None:
                body = raw[-suffix:]
                return body, len(raw) - len(body), len(raw) - 1, len(raw)
            return raw[start:end + 1], start, end, len(raw)

        with patch("inspect_remote_zip.request_range", side_effect=fake_range):
            prefix = fetch_member_prefix("https://example.invalid/archive.zip", entry, len(raw))
        self.assertEqual(parse_macho_architectures(prefix), ["arm64"])

    def test_validates_macho_against_xcframework_manifest(self):
        metadata = {
            "VLCKit.xcframework/Info.plist": {
                "AvailableLibraries": [{
                    "LibraryIdentifier": "ios-arm64",
                    "LibraryPath": "VLCKit.framework",
                    "SupportedArchitectures": ["arm64"],
                }]
            }
        }
        entry = type("Entry", (), {
            "name": "VLCKit.xcframework/ios-arm64/VLCKit.framework/VLCKit"
        })()
        with patch("inspect_remote_zip.fetch_member_prefix",
                   return_value=struct.pack("<Iii", 0xFEEDFACF, 0x0100000C, 0)):
            inspect_macho_binaries("https://example.invalid/archive.zip", [entry], metadata, 100)

    def test_rejects_macho_manifest_architecture_mismatch(self):
        metadata = {
            "VLCKit.xcframework/Info.plist": {
                "AvailableLibraries": [{
                    "LibraryIdentifier": "ios-arm64",
                    "LibraryPath": "VLCKit.framework",
                    "SupportedArchitectures": ["x86_64"],
                }]
            }
        }
        entry = type("Entry", (), {
            "name": "VLCKit.xcframework/ios-arm64/VLCKit.framework/VLCKit"
        })()
        with patch("inspect_remote_zip.fetch_member_prefix",
                   return_value=struct.pack("<Iii", 0xFEEDFACF, 0x0100000C, 0)):
            with self.assertRaises(InspectionError):
                inspect_macho_binaries("https://example.invalid/archive.zip", [entry], metadata, 100)

    def test_parses_thin_arm64_macho_header(self):
        header = struct.pack("<Iii", 0xFEEDFACF, 0x0100000C, 0)
        self.assertEqual(parse_macho_architectures(header), ["arm64"])

    def test_parses_fat_simulator_macho_header(self):
        header = struct.pack(">II", 0xCAFEBABE, 2)
        header += struct.pack(">iiIII", 0x0100000C, 0, 4096, 100, 12)
        header += struct.pack(">iiIII", 0x01000007, 3, 8192, 100, 12)
        self.assertEqual(parse_macho_architectures(header), ["arm64", "x86_64"])

    def test_parses_arm64_32_macho_header(self):
        header = struct.pack("<Iii", 0xFEEDFACF, 0x0200000C, 0)
        self.assertEqual(parse_macho_architectures(header), ["arm64_32"])

    def test_rejects_unknown_macho_header(self):
        with self.assertRaises(InspectionError):
            parse_macho_architectures(b"NOPE0000")

    def test_rejects_non_zip_tail(self):
        with self.assertRaises(InspectionError):
            find_eocd(b"not a zip archive", 0)

    def test_rejects_zip64_sentinel(self):
        eocd = struct.pack("<4s4H2IH", b"PK\\x05\\x06", 0, 0, 0xFFFF, 0xFFFF, 0, 0, 0)
        with self.assertRaises(InspectionError):
            find_eocd(eocd, 0)

    def test_rejects_corrupt_central_directory(self):
        with self.assertRaises(InspectionError):
            parse_central_directory(b"not a central directory", 1)


if __name__ == "__main__":
    unittest.main()
