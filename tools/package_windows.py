"""Package the exported Windows game, editable project and validation evidence."""
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "EchoesOfAethel-Fase20-Estabilizado-Windows-x64.zip"
SOURCE_DIRS = ("assets", "scenes", "scripts", "src", "tests", "tools", "docs", "data", "licenses", ".github")


def files_under(folder):
    return sorted(p for p in folder.rglob("*") if p.is_file() and ".godot" not in p.parts and "__pycache__" not in p.parts and not p.name.endswith(".import"))


def main():
    game = ROOT / "teste-fase20"
    executable = game / "EchoesOfAethel-Fase20.exe"
    pack = game / "EchoesOfAethel-Fase20.pck"
    if not executable.exists() or not pack.exists():
        raise RuntimeError("Export the Windows game before packaging")
    if executable.read_bytes()[:2] != b"MZ" or pack.stat().st_size < 100_000:
        raise RuntimeError("Invalid or incomplete executable/PCK")
    entries = []
    for path in files_under(game):
        if path.name != ".gdignore":
            entries.append((path, "jogo/" + path.relative_to(game).as_posix()))
    for directory in SOURCE_DIRS:
        for path in files_under(ROOT / directory):
            entries.append((path, "fonte/" + path.relative_to(ROOT).as_posix()))
    for name in ("README.md", "project.godot", "export_presets.cfg", "GERAR_TESTE.ps1", ".gitignore"):
        path = ROOT / name
        entries.append((path, "fonte/" + name))
    evidence = ROOT / "relatorios-fase20"
    for path in sorted(evidence.glob("*")):
        if path.is_file() and (path.name.endswith("-final.log") or path.name in ("results.json", "release-menu.log", "release-gameplay.log", "exportacao-release.log") or (path.suffix == ".png" and not path.name.startswith(("pdf", "release"))) or path.name == "release-validado.png"):
            entries.append((path, "evidencias/" + path.name))
    provenance = ROOT / ".tools/templates/provenance.json"
    if provenance.exists():
        entries.append((provenance, "evidencias/template-provenance.json"))
    manifest = {name: hashlib.sha256(path.read_bytes()).hexdigest() for path, name in entries}
    if len(manifest) != len(entries):
        raise RuntimeError("Duplicate archive entry")
    with zipfile.ZipFile(OUTPUT, "w", zipfile.ZIP_DEFLATED, compresslevel=7) as archive:
        for path, name in entries:
            archive.write(path, name)
        archive.writestr("MANIFEST-SHA256.json", json.dumps(manifest, indent=2, ensure_ascii=False))
        archive.write(ROOT / "docs/TESTING.md", "LEIA-ME.md")
    with zipfile.ZipFile(OUTPUT) as archive:
        error = archive.testzip()
        if error:
            raise RuntimeError("CRC failed: " + error)
        for name in ("jogo/EchoesOfAethel-Fase20.exe", "jogo/EchoesOfAethel-Fase20.pck"):
            if hashlib.sha256(archive.read(name)).hexdigest() != manifest[name]:
                raise RuntimeError("Hash mismatch: " + name)
    print(json.dumps({"archive": OUTPUT.name, "bytes": OUTPUT.stat().st_size, "entries": len(entries) + 2,
                      "sha256": hashlib.sha256(OUTPUT.read_bytes()).hexdigest()}, indent=2))


if __name__ == "__main__":
    main()
