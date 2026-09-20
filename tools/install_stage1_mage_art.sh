#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$REPO_ROOT/assets/art/heroes/stage1_mage"
DEFAULT_1="$HOME/storage/downloads/stage1_mage_game_ready.zip"
DEFAULT_2="$HOME/storage/shared/Download/stage1_mage_game_ready.zip"
DEFAULT_3="$REPO_ROOT/stage1_mage_game_ready.zip"

ZIP_PATH="${1:-}"

if [ -z "$ZIP_PATH" ]; then
  for candidate in "$DEFAULT_1" "$DEFAULT_2" "$DEFAULT_3"; do
    if [ -f "$candidate" ]; then
      ZIP_PATH="$candidate"
      break
    fi
  done
fi

if [ -z "$ZIP_PATH" ] || [ ! -f "$ZIP_PATH" ]; then
  echo "stage1_mage_game_ready.zip 을 찾지 못했습니다."
  echo "사용법: bash tools/install_stage1_mage_art.sh /경로/stage1_mage_game_ready.zip"
  exit 1
fi

mkdir -p "$DEST_DIR"

unzip -p "$ZIP_PATH" stage1_mage_spritesheet.png > "$DEST_DIR/stage1_mage_spritesheet.png"
unzip -p "$ZIP_PATH" sprite_manifest.json > "$DEST_DIR/sprite_manifest.json"

echo "Stage 1 마법사 스프라이트 설치 완료:"
echo "  $DEST_DIR/stage1_mage_spritesheet.png"
echo "  $DEST_DIR/sprite_manifest.json"
echo
echo "Godot을 다시 열거나 프로젝트를 다시 스캔하면 자동 import 됩니다."
