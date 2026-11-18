import io
import struct
import sys
import unittest
import zipfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "Scripts"))
from inspect_remote_zip import InspectionError, find_eocd, parse_central_directory


class RemoteZipInspectorTests(unittest.TestCase):
    def make_archive(self):
        output = io.BytesIO()
        with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr("VLCKit.xcframework/Info.plist", b"plist")
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

    def test_rejects_non_zip_tail(self):
        with self.assertRaises(InspectionError):
            find_eocd(b"not a zip archive", 0)

    def test_rejects_zip64_sentinel(self):
        # EOCD with the ZIP64 entry-count sentinel.
        eocd = struct.pack("<4s4H2IH", b"PK\x05\x06", 0, 0, 0xFFFF, 0xFFFF, 0, 0, 0)
        with self.assertRaises(InspectionError):
            find_eocd(eocd, 0)

    def test_rejects_corrupt_central_directory(self):
        with self.assertRaises(InspectionError):
            parse_central_directory(b"not a central directory", 1)


if __name__ == "__main__":
    unittest.main()
