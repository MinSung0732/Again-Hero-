"""Keep a real server polling while one client blocks during cold map setup."""
import argparse
from pathlib import Path
import subprocess
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('godot')
    parser.add_argument('fixture', type=Path)
    args = parser.parse_args()
    logs = args.fixture / 'cold_load_logs'
    logs.mkdir(exist_ok=True)
    processes = []
    try:
        for role in ('server', 'hero', 'demon'):
            path = logs / (role + '.log')
            handle = path.open('w')
            process = subprocess.Popen([
                args.godot, '--headless', '--path', str(args.fixture),
                '--script', 'res://tests/online_cold_load_regression.gd', '--', role,
            ], stdout=handle, stderr=subprocess.STDOUT)
            processes.append((role, process, handle, path))
            if role == 'server':
                deadline = time.monotonic() + 10
                while 'COLD_LOAD_SERVER_READY' not in path.read_text():
                    if process.poll() is not None or time.monotonic() > deadline:
                        raise RuntimeError('Server failed to start; inspect ' + str(path))
                    time.sleep(0.02)
        for role, process, _, path in processes:
            code = process.wait(timeout=40)
            content = path.read_text()
            marker = 'COLD_LOAD_SERVER_PASS' if role == 'server' else 'COLD_LOAD_CLIENT_PASS role=' + role
            if code or marker not in content or 'ERROR:' in content:
                raise RuntimeError('Cold loading regression failed; inspect ' + str(path))
        print('ONLINE_COLD_LOAD_THREE_PROCESS_PASS delay=PEER_IDLE_TIMEOUT+0.5s')
    finally:
        for _, process, handle, _ in processes:
            if process.poll() is None:
                process.terminate()
                process.wait(timeout=5)
            handle.close()


if __name__ == '__main__':
    main()
