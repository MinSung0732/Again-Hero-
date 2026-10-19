"""Actual heal PNG/imports and actor, including a source-PNG-free PCK check."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess

from PIL import Image


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--baseline', required=True)
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    out = args.destination.resolve()
    if out == repo or repo in out.parents:
        raise SystemExit('Use a directory outside the repository')
    out.mkdir(parents=True, exist_ok=True)

    def committed(path):
        return subprocess.check_output(['git', 'show', args.baseline + ':' + path], cwd=repo)

    source = (repo / 'src/battle/heal_item.gd').read_text()
    original = committed('src/battle/heal_item.gd').decode()
    assert source[:source.index('func _load_texture(')] == original[:original.index('func _load_texture(')]
    directory = re.search(r'const HEAL_FRAME_DIR := "res://([^"]+)"', source)[1]
    count = int(re.search(r'const FRAME_COUNT := (\d+)', source)[1])
    paths = [directory + '/float_%02d.png' % index for index in range(1, count + 1)]
    expected = []
    for path in paths:
        dest = out / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes((repo / path).read_bytes() if (repo / path).exists() else committed(path))
        import_path = path + '.import'
        dest.with_name(dest.name + '.import').write_bytes((repo / import_path).read_bytes() if (repo / import_path).exists() else committed(import_path))
        image = Image.open(dest).convert('RGBA')
        x0, y0, x1, y1 = image.getchannel('A').getbbox()
        expected.append({'path': 'res://' + path, 'width': image.width, 'height': image.height,
                         'rect': [x0, y0, x1-x0, y1-y0], 'sha256': hashlib.sha256(image.tobytes()).hexdigest()})
    files = ['src/battle/heal_item.gd', 'src/battle/HealItem.tscn',
             'src/systems/pickup_placement.gd', 'tests/heal_item_resource_smoke.gd']
    for path in files:
        dest = out / path; dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(repo / path, dest)
    (out / 'expected.json').write_text(json.dumps(expected))
    (out / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="HealResourceFixture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    # Like the existing frontier export fixture: retain import remaps and CTEX,
    # deliberately omit original PNG files to exercise packaged resource lookup.
    packer = '''extends SceneTree
func _initialize() -> void:
	var pack := PCKPacker.new()
	assert(pack.pck_start(OS.get_cmdline_user_args()[0]) == OK)
	for path in FILES:
		assert(pack.add_file("res://"+path,ProjectSettings.globalize_path("res://"+path)) == OK)
	for entry in JSON.parse_string(FileAccess.get_file_as_string("res://expected.json")):
		var path: String = entry.path + ".import"
		var imported := ConfigFile.new()
		assert(imported.load(path) == OK)
		var ctex: String = imported.get_value("remap","path")
		assert(pack.add_file(path,ProjectSettings.globalize_path(path)) == OK)
		assert(pack.add_file(ctex,ProjectSettings.globalize_path(ctex)) == OK)
	assert(pack.flush() == OK)
	print("HEAL_RESOURCE_PCK_BUILT without source PNG")
	quit()
'''.replace('FILES', json.dumps(files + ['project.godot', 'expected.json']))
    (out / 'pack.gd').write_text(packer)
    print(f'Actual PNG frames: {len(paths)}; other heal actor methods/declarations unchanged')


if __name__ == '__main__':
    main()
