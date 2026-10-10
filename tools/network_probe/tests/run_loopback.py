"""Run one real ENet server and two separate Godot clients on loopback."""
import argparse,json,subprocess,tempfile,time,socket
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('godot');a=p.parse_args()
root=Path(__file__).resolve().parents[1]
# Pick an available UDP test port. A bind race fails visibly; never change firewall.
with socket.socket(socket.AF_INET,socket.SOCK_DGRAM) as s:
    s.bind(('127.0.0.1',0));port=s.getsockname()[1]
processes=[];streams=[]
with tempfile.TemporaryDirectory(prefix='ah-enet-') as tmp:
    try:
        for mode in ['server','hero','demon']:
            log=Path(tmp)/(mode+'.log');stream=log.open('w');streams.append(stream)
            proc=subprocess.Popen([a.godot,'--headless','--path',str(root),'--script','res://tests/peer.gd','--',mode,str(port)],stdout=stream,stderr=subprocess.STDOUT)
            processes.append((mode,proc,log))
            # Observe readiness/assignment so process startup speed cannot swap roles.
            marker = 'READY server 0' if mode == 'server' else ('ROLE 1' if mode == 'hero' else 'ROLE 2')
            ready_deadline=time.monotonic()+8
            while marker not in log.read_text() and proc.poll() is None and time.monotonic()<ready_deadline:time.sleep(0.02)
            assert marker in log.read_text(),(mode,log.read_text())
        deadline=time.monotonic()+25
        while any(proc.poll() is None for _,proc,_ in processes) and time.monotonic()<deadline:time.sleep(0.05)
        results=[]
        for mode,proc,log in processes:
            content=log.read_text()
            if proc.poll()!=0 or 'ERROR' in content or 'WARNING' in content:
                raise RuntimeError(mode+' failed:\n'+content)
            lines=[line[7:] for line in content.splitlines() if line.startswith('RESULT ')]
            assert len(lines)==1,(mode,content)
            results.append(json.loads(lines[0]))
        server,hero,demon=results
        assert hero['role']==1 and demon['role']==2,results
        assert all(r['winner']==1 and r['kills']>=6 and r['moved'] for r in results),results
        assert hero['snapshots']>10 and demon['snapshots']>10,results
        assert server['rejected']>=2,results
        assert server['state']==hero['state']==demon['state'],'Final server/client state mismatch'
        print('LOOPBACK PASS: 3 processes, server-bound roles, movement, summon, damage, cooldown, rejection, identical final state')
        print(json.dumps([{k:v for k,v in r.items() if k!='state'} for r in results]))
    finally:
        for _,proc,_ in processes:
            if proc.poll() is None:proc.terminate()
            try:proc.wait(timeout=3)
            except subprocess.TimeoutExpired:proc.kill();proc.wait()
        for stream in streams:stream.close()
