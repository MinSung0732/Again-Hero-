"""Measure speech and optionally normalize WAVs offline using a shared loudness policy.

Requires ffmpeg. Runtime decoding/AGC is not added. Original revisions
remain in git; a report records source/output hashes and measurements.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
import math
from pathlib import Path
import re
import subprocess
import tempfile
import wave


def run(command):
    return subprocess.run(command, check=True, capture_output=True, text=True)


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def measure(path, policy):
    result = run(['ffmpeg', '-hide_banner', '-nostats', '-i', str(path), '-af',
                  f'loudnorm=I={policy["target_lufs"]}:TP={policy["maximum_true_peak_db"]}:print_format=json', '-f', 'null', '-'])
    stats = json.loads(re.findall(r'\{\s*"input_i".*?\}', result.stderr, re.S)[-1])
    for key in ['input_i', 'input_tp', 'input_lra', 'input_thresh']:
        if not math.isfinite(float(stats[key])):
            raise ValueError(f'Cannot normalize silent/nonfinite input: {path}')
    return {key: stats[key] for key in ['input_i', 'input_tp', 'input_lra', 'input_thresh']}


def audio_format(path):
    with wave.open(str(path), 'rb') as source:
        return {'rate': source.getframerate(), 'channels': source.getnchannels(),
                'sample_width': source.getsampwidth(), 'frames': source.getnframes()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    parser.add_argument('--policy', type=Path, default=Path(__file__).parent/'audio/hero_voice_loudness_policy.json')
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    directory = args.directory.resolve()
    policy = json.loads(args.policy.read_text())
    paths = sorted(directory.rglob('*.wav'))
    if not paths:
        raise SystemExit('No WAVs found')
    if policy['limiter_ceiling_db'] > policy['maximum_true_peak_db']:
        raise SystemExit('Normalizer peak target must leave room below output ceiling')
    with tempfile.TemporaryDirectory(prefix='hero-voice-normalize-') as temp:
        def process(item):
            index, path = item
            before = measure(path, policy)
            fmt = audio_format(path)
            row = {'path': path.relative_to(directory).as_posix(), 'source_sha256': digest(path),
                   'format': fmt, 'before': before}
            if not args.apply:
                return row
            if fmt['sample_width'] != 2:
                raise ValueError(f'Expected PCM16 source; preserve/extend encoding policy first: {path}')
            gain_db = policy['target_lufs'] - float(before['input_i'])
            ceiling = 10.0 ** (policy['limiter_ceiling_db'] / 20.0)
            for attempt in range(int(policy['maximum_gain_passes'])):
                output = Path(temp)/f'{index}-{attempt}.wav'
                filters = (f'volume={gain_db}dB,'
                           f'aresample={fmt["rate"] * int(policy["oversample_factor"])},'
                           f'alimiter=limit={ceiling}:level=false:latency=true:'
                           f'attack={policy["limiter_attack_ms"]}:release={policy["limiter_release_ms"]},'
                           f'aresample={fmt["rate"]}')
                run(['ffmpeg', '-hide_banner', '-nostats', '-y', '-i', str(path),
                     '-af', filters, '-ac', str(fmt['channels']), '-c:a', 'pcm_s16le', str(output)])
                after = measure(output, policy)
                error = policy['target_lufs'] - float(after['input_i'])
                if abs(error) <= policy['loudness_tolerance_lu'] + 1e-6:
                    break
                gain_db += error
            else:
                raise ValueError(f'LUFS outside tolerance: {path}: {after["input_i"]}')
            if audio_format(output) != fmt:
                raise ValueError(f'Audio format/length changed: {path}')
            if float(after['input_tp']) > policy['maximum_true_peak_db']:
                raise ValueError(f'True peak above ceiling: {path}: {after["input_tp"]}')
            row.update(output_sha256=digest(output), after=after, gain_db=round(gain_db, 2),
                       method='gain_and_oversampled_peak_limiter', passes=attempt+1,
                       temporary_output=str(output))
            return row
        with ThreadPoolExecutor(max_workers=int(policy['workers'])) as pool:
            rows = list(pool.map(process, enumerate(paths)))
        # Validate the whole batch before writing any source file.
        for path, row in zip(paths, rows):
            if digest(path) != row['source_sha256']:
                raise ValueError(f'Source changed during analysis: {path}')
        if args.apply:
            for path, row in zip(paths, rows):
                path.write_bytes(Path(row.pop('temporary_output')).read_bytes())
        report = {'policy': policy, 'applied': args.apply,
                  'ffmpeg_version': run(['ffmpeg', '-version']).stdout.splitlines()[0], 'files': rows}
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n')
    print(json.dumps({'files': len(rows), 'applied': args.apply,
                      'before_lufs_range': [min(float(r['before']['input_i']) for r in rows),
                                            max(float(r['before']['input_i']) for r in rows)],
                      'after_lufs_range': [min(float(r['after']['input_i']) for r in rows),
                                           max(float(r['after']['input_i']) for r in rows)] if args.apply else None}))


if __name__ == '__main__':
    main()
