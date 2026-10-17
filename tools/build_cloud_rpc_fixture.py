"""Actual CloudStore/HTTP/codec/cache; private account and loopback endpoint."""
from pathlib import Path
import subprocess,sys,shutil
repo=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve()
subprocess.run([sys.executable,str(repo/'tools/build_nickname_fixture.py'),str(out)],check=True)
shutil.copy2(repo/'tests/cloud_rpc_wire_smoke.gd',out/'tests/cloud_rpc_wire_smoke.gd')
