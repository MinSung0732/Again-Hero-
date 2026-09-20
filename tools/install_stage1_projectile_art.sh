#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$REPO_ROOT/assets/art/projectiles/stage1_mage"

DEFAULT_1="$HOME/storage/downloads/stage1_mage_projectile_ready.zip"
DEFAULT_2="$HOME/storage/shared/Download/stage1_mage_projectile_ready.zip"
DEFAULT_3="$REPO_ROOT/stage1_mage_projectile_ready.zip"

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
  echo "stage1_mage_projectile_ready.zip 을 찾지 못했습니다."
  echo "사용법:"
  echo "  bash tools/install_stage1_projectile_art.sh /경로/stage1_mage_projectile_ready.zip"
  exit 1
fi

mkdir -p "$DEST_DIR"

unzip -p "$ZIP_PATH" stage1_mage_projectile_sheet.png > "$DEST_DIR/stage1_mage_projectile_sheet.png"
unzip -p "$ZIP_PATH" projectile_01.png > "$DEST_DIR/projectile_01.png"
unzip -p "$ZIP_PATH" projectile_02.png > "$DEST_DIR/projectile_02.png"
unzip -p "$ZIP_PATH" projectile_03.png > "$DEST_DIR/projectile_03.png"
unzip -p "$ZIP_PATH" projectile_04.png > "$DEST_DIR/projectile_04.png"
unzip -p "$ZIP_PATH" manifest.json > "$DEST_DIR/manifest.json"

SHEET_BYTES="$(wc -c < "$DEST_DIR/stage1_mage_projectile_sheet.png")"
if [ "$SHEET_BYTES" -lt 1000 ]; then
  echo "오류: 투사체 스프라이트시트 추출에 실패했습니다. (${SHEET_BYTES} bytes)"
  exit 1
fi

echo "Stage 1 마법사 투사체 설치 완료 (${SHEET_BYTES} bytes):"
echo "  $DEST_DIR/stage1_mage_projectile_sheet.png"
echo "  $DEST_DIR/projectile_01.png"
echo "  $DEST_DIR/projectile_02.png"
echo "  $DEST_DIR/projectile_03.png"
echo "  $DEST_DIR/projectile_04.png"
echo "  $DEST_DIR/manifest.json"
echo
echo "최신 코드는 imported texture가 늦어도 raw PNG를 직접 읽어 표시합니다."
