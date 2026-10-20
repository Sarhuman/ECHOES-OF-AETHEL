"""Fetch only the Windows x64 release entry from the official Godot TPZ.

HTTP byte ranges avoid downloading templates for every other platform.
ZipFile validates the selected entry CRC; provenance is recorded beside it.
"""
import io
import json
import hashlib
from pathlib import Path
import urllib.request
import zipfile

VERSION = "4.7.2"
URL = f"https://github.com/godotengine/godot-builds/releases/download/{VERSION}-stable/Godot_v{VERSION}-stable_export_templates.tpz"


class RemoteZip(io.RawIOBase):
    def __init__(self):
        with urllib.request.urlopen(urllib.request.Request(URL, method="HEAD"), timeout=60) as response:
            self.url = response.url
            self.size = int(response.headers["Content-Length"])
        self.position = 0

    def seekable(self):
        return True

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position + offset if whence == 1 else self.size + offset)
        return self.position

    def tell(self):
        return self.position

    def read(self, size=-1):
        if size < 0:
            size = self.size - self.position
        size = min(size, self.size - self.position)
        if size <= 0:
            return b""
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{self.position + size - 1}"})
        with urllib.request.urlopen(request, timeout=120) as response:
            if response.status != 206:
                raise RuntimeError("Server did not honor HTTP Range; refusing whole archive download")
            data = response.read()
        if len(data) != size:
            raise RuntimeError(f"Incomplete range: {len(data)} != {size}")
        self.position += len(data)
        return data


def main():
    target = Path(__file__).resolve().parents[1] / ".tools" / "templates"
    target.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(RemoteZip()) as archive:
        entries = [e for e in archive.infolist() if e.filename.endswith("/windows_release_x86_64.exe")]
        if len(entries) != 1:
            raise RuntimeError("Expected exactly one Windows x64 release template")
        entry = entries[0]
        content = archive.read(entry)
    output = target / "windows_release_x86_64.exe"
    output.write_bytes(content)
    metadata = {"source": URL, "entry": entry.filename, "crc32": f"{entry.CRC:08x}", "sha256": hashlib.sha256(content).hexdigest(), "bytes": len(content)}
    (target / "provenance.json").write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(json.dumps(metadata, indent=2))


if __name__ == "__main__":
    main()
