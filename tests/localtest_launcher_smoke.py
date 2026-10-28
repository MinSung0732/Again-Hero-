"""Exercise the actual PowerShell launcher with fast-failing/successful processes.
Usage (POSIX host): python tests/localtest_launcher_smoke.py /path/to/pwsh
Windows PowerShell 5.1 and the real Windows executable still need device testing.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

repo = Path(__file__).resolve().parents[1]
pwsh = str(Path(sys.argv[1]).resolve())
checks = 0


def check(ok, label):
    global checks
    checks += 1
    if not ok:
        raise AssertionError(label)


with tempfile.TemporaryDirectory(prefix="again_launcher_") as temporary:
    work = Path(temporary)
    project = work / "게임 테스트" / "Again-Hero-"
    (project / "tools").mkdir(parents=True)
    launcher = project / "tools/localtest_server.ps1"
    shutil.copyfile(repo / "tools/localtest_server.ps1", launcher)
    fake = work / "Godot_console.exe"
    fake.write_text("#!" + sys.executable + "\n" + '''import os, sys
assert '--headless' in sys.argv and '--localtest' in sys.argv
assert os.environ['AGAIN_HERO_BIND'] == '127.0.0.1'
assert os.environ['AGAIN_HERO_PORT'] == '32119'
print('FAST_STDOUT_RETAINED', flush=True)
print('PROJECT_PATH=' + sys.argv[sys.argv.index('--path')+1], flush=True)
mode = os.environ['LAUNCHER_TEST_MODE']
if mode == 'ready':
    print('AGAIN_HERO_MATCH_SERVER ready port=32119', flush=True)
    print('LOCALTEST invitation code: ' + 'a'*48, flush=True)
    sys.exit(0)
if mode == 'flood':
    for index in range(4096):
        print('Diagnostic filler ' + str(index) + ' ' + 'x'*64, file=sys.stderr)
print('SCRIPT ERROR: mock startup failure 한글', file=sys.stderr, flush=True)
sys.exit(1)
''', encoding="utf-8")
    fake.chmod(0o755)
    environment = dict(os.environ, AGAIN_HERO_GODOT=str(fake), AGAIN_HERO_BIND="0.0.0.0",
                       TMPDIR=str(work), TEMP=str(work), TMP=str(work), LAUNCHER_PATH=str(launcher))
    syntax = subprocess.run([pwsh, "-NoProfile", "-Command",
                            '$tokens=$null; $parseErrors=$null; $null=[System.Management.Automation.Language.Parser]::ParseFile($env:LAUNCHER_PATH,[ref]$tokens,[ref]$parseErrors); if($parseErrors.Count){$parseErrors;exit 1}'],
                            env=environment, capture_output=True, text=True, timeout=20)
    check(syntax.returncode == 0, "PowerShell parser accepts the real launcher")
    for mode in ["fail", "flood", "ready"]:
        environment["LAUNCHER_TEST_MODE"] = mode
        process = subprocess.run([pwsh, "-NoProfile", "-File", str(launcher), "-Port", "32119"],
                                 env=environment, capture_output=True, text=True, timeout=20)
        output = process.stdout + process.stderr
        check(process.returncode == (0 if mode == "ready" else 1), "child exit code preserved: " + mode)
        check("FAST_STDOUT_RETAINED" in output, "stdout drained after immediate exit: " + mode)
        check("PROJECT_PATH=" + str(project) in output, "spaces and Unicode path arguments preserved: " + mode)
        match = re.search(r"서버 로그 : ([^\r\n]+)", output)
        check(match is not None, "log path shown: " + mode)
        log = Path(match[1]).read_text(encoding="utf-8-sig")
        if mode == "ready":
            check("a"*48 in output and "a"*48 not in log and "[redacted]" in log,
                  "invitation visible in console and redacted in log")
        else:
            check("SCRIPT ERROR: mock startup failure 한글" in output and "SCRIPT ERROR: mock startup failure 한글" in log,
                  "stderr visible and persisted: " + mode)
        if mode == "flood":
            check(len(log) > 300000, "full stderr retained without blocking the pipe")
print("LOCALTEST_LAUNCHER_PASS checks=" + str(checks))
