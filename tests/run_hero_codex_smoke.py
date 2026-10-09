"""Run the production codex projection/view without login, Battle or save autoloads."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument("--godot", default=shutil.which("godot") or shutil.which("godot4"))
args = parser.parse_args()
if not args.godot:
    parser.error("Godot 4 실행 파일 경로를 --godot으로 지정하세요.")
repo = Path(__file__).resolve().parents[1]
files = [
    "src/data/hero_codex_catalog.gd", "src/data/hero_skill_descriptions.gd",
    "src/data/hero_profiles.gd", "src/data/hero_ai_profiles.gd",
    "src/data/hero_augment_catalog.gd", "src/data/stage_catalog.gd",
    "src/ui/lobby_hero_codex_view.gd", "src/ui/drag_safe_button.gd",
    "tests/hero_codex_smoke.gd",
    "src/systems/stage_progress.gd", "src/systems/account_save_scope.gd",
    "assets/art/UI/hero_codex/lock_closed.svg", "assets/art/UI/hero_codex/lock_open.svg",
]
with tempfile.TemporaryDirectory(prefix="hero-codex-") as temp:
    fixture = Path(temp)
    for name in files + ["assets/fonts/Galmuri11.ttf"]:
        source = repo / name
        if name.endswith(".ttf") and not source.is_file():
            continue
        target = fixture / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
    (fixture / "project.godot").write_text(
        'config_version=5\n[application]\nconfig/name="HeroCodexFixture"\n'
        '[display]\nwindow/size/viewport_width=1080\nwindow/size/viewport_height=1920\n'
        '[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding="utf-8")
    result = subprocess.run([args.godot, "--headless", "--path", str(fixture),
                             "--script", "res://tests/hero_codex_smoke.gd"], timeout=45)
    raise SystemExit(result.returncode)
