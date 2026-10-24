"""Inventory tracked baseline files and literal resource references; no downloads."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]

def main():
    names = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode('utf8').split('\0')
    inventory, missing, dynamic, fixtures = [], [], [], []
    for name in filter(None, names):
        path = ROOT / name
        if not path.is_file():
            missing.append({'file': name, 'reason': 'tracked file absent'})
            continue
        inventory.append({'path': name, 'bytes': path.stat().st_size,
                          'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
        if path.suffix not in {'.gd', '.tscn', '.tres', '.godot'}:
            continue
        for ref in re.findall(r'[\"\'](res://[^\"\'\n]+)[\"\']', path.read_text(encoding='utf8')):
            if '%' in ref or '*' in ref or ref.endswith('/'):
                dynamic.append({'file': name, 'reference': ref})
            elif name == 'tests/test_phase24.gd' and ref == 'res://bad.gd':
                fixtures.append({'file': name, 'reference': ref, 'reason': 'intentional invalid persisted-choice rejection fixture'})
            elif not (ROOT / ref[6:]).exists():
                missing.append({'file': name, 'reference': ref})
    report = {'tracked_files': len(inventory), 'missing': missing,
              'dynamic_references_not_statically_resolved': dynamic, 'intentional_invalid_test_fixtures': fixtures, 'files': inventory}
    target = ROOT / 'relatorios-fase20/us01-inventory.json'
    target.parent.mkdir(exist_ok=True)
    target.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf8')
    print(json.dumps({'tracked_files': len(inventory), 'missing': missing, 'dynamic': len(dynamic)}))
    return bool(missing)

if __name__ == '__main__':
    raise SystemExit(main())
