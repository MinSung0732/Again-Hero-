"""Isolate production presentation scripts/assets, without save/login/battle autoloads."""
import argparse
from pathlib import Path
import re
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--godot", required=True)
args = parser.parse_args()
repo = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="manticore-cutscene-") as temp:
    fixture = Path(temp)
    pending = ["tests/manticore_cutscene_smoke.gd", "src/ui/manticore_gacha_view.gd"]
    copied = set()
    while pending:
        name = pending.pop()
        if name in copied:
            continue
        copied.add(name)
        target = fixture / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(repo / name, target)
        if name.endswith(".gd"):
            pending.extend(re.findall(r'(?:preload|load)\("res://([^"%]+\.(?:gd|gdshader))"\)', target.read_text()))
            # ShopCatalog exposes combat PackedScenes; this test never instantiates them.
            for scene in re.findall(r'preload\("res://(src/monsters/[^"%]+\.tscn)"\)', target.read_text()):
                stub = fixture / scene
                stub.parent.mkdir(parents=True, exist_ok=True)
                stub.write_text('[gd_scene format=3]\n[node name="UninstantiatedCombatDependency" type="Node2D"]\n')
    for name in ["assets/art/effects/gatcha/manticore", "assets/art/Transcendent_monster/manticore/frames", "assets/art/UI/clean_frames"]:
        shutil.copytree(repo / name, fixture / name, ignore=shutil.ignore_patterns("*.import"))
    for name in ["assets/fonts/Galmuri11.ttf", "src/ui/manticore_silhouette_reveal.gdshader", "assets/audio/sfx/bulgasal/burrow.wav", "assets/audio/sfx/bulgasal/rock.wav"]:
        target = fixture / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(repo / name, target)
    (fixture / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="ManticoreCutsceneFixture"\n'
        '[display]\nwindow/size/viewport_width=540\nwindow/size/viewport_height=960\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
    for command in [[args.godot, "--headless", "--path", temp, "--editor", "--import"],
                    [args.godot, "--headless", "--path", temp, "--script", "res://tests/manticore_cutscene_smoke.gd"]]:
        result = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60)
        if result.returncode or "ERROR:" in result.stdout or "MANTICORE_CUTSCENE PASS" not in result.stdout and command[-1].endswith(".gd"):
            print(result.stdout[-12000:])
            raise SystemExit(result.returncode or 1)
    print(result.stdout.strip())
