"""Read-only release configuration audit. A pass does not certify a store build."""
from pathlib import Path
import json
import os
import re
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]

def audit(root=ROOT):
    issues = []
    preset = root / "export_presets.cfg"
    text = preset.read_text(encoding="utf-8") if preset.exists() else ""
    def option(key):
        match = re.search(r"^" + re.escape(key) + r"=(.+)$", text, re.M)
        return match.group(1).strip().strip('"') if match else ""
    if not text:
        issues.append("Android export preset missing")
    if option("platform") != "Android":
        issues.append("Android platform preset missing")
    if option("gradle_build/use_gradle_build") != "true" or option("gradle_build/export_format") != "1":
        issues.append("Gradle AAB export required")
    if not option("gradle_build/target_sdk").isdigit() or int(option("gradle_build/target_sdk") or 0) < 36:
        issues.append("targetSdk 36+ required (2026-10-13 baseline)")
    if option("architectures/arm64-v8a") != "true":
        issues.append("ARM64 required")
    if option("package/signed") != "true":
        issues.append("Release signing must be enabled")
    if not re.fullmatch(r"[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*){2,}", option("package/unique_name")):
        issues.append("Valid Android package ID required")
    if not option("version/code").isdigit() or int(option("version/code") or 0) <= 0:
        issues.append("Positive versionCode required")
    signing_path = os.getenv("GODOT_ANDROID_KEYSTORE_RELEASE_PATH", option("keystore/release"))
    signing_user = os.getenv("GODOT_ANDROID_KEYSTORE_RELEASE_USER", option("keystore/release_user"))
    signing_password = os.getenv("GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD", option("keystore/release_password"))
    if not signing_path or not signing_user or not signing_password:
        issues.append("Release signing credentials unavailable; use Godot environment variables")
    elif not Path(signing_path.replace("res://", str(root) + "/")).is_file():
        issues.append("Release keystore not found")
    if not (root / "android/build/build.gradle").exists() and not (root / "android/build/build.gradle.kts").exists():
        issues.append("Godot Android build template not installed")
    engine = shutil.which("godot") or shutil.which("godot4") or os.getenv("GODOT_BIN", "")
    if not engine or not Path(engine).is_file() or not os.access(engine, os.X_OK):
        issues.append("Godot executable unavailable")
    return {"configuration_status": "BLOCKED" if issues else "PASS", "issues": issues,
            "package_id": option("package/unique_name"), "target_sdk": option("gradle_build/target_sdk"),
            "runtime_verified": False, "store_ready": False,
            "remaining_evidence": ["Signed release AAB and final manifest", "16 KB native-library compatibility",
                                   "Android touch, lifecycle, login and save recovery", "First-minute human playtest",
                                   "Play Console disclosures and required testing"]}

if __name__ == "__main__":
    result = audit()
    print(json.dumps(result, ensure_ascii=False, indent=2))
    sys.exit(1 if result["configuration_status"] == "BLOCKED" else 0)
