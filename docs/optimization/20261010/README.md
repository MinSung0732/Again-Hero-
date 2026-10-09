# 2026-10-10 optimization evidence

- `baseline_inventory.json`: tracked src GDScript inventory at the preserved baseline; lexical hints, not runtime counts.
- `before_after.zip` / `code_manifest.json`: complete 13 production scripts with original/current contents and SHA256. New helpers have no Before version.
- `changes.patch`: production source/UID diff from baseline through the two code commits. Do not apply twice.
- `benchmark.json`: warmed 7-sample CPU microbenchmarks, Godot4.5.1 Linux headless, final run without competing Godot tests. Not FPS/GPU/RSS evidence.
- `regression_summary.json`: all118 smoke exits/diagnostics,21 failure Before/After comparisons with separate Linux user data, final3 targeted clean checks.
- `regression_logs.zip`: broad, baseline, isolated, final import/test/benchmark logs. Timeouts are fixture/runner outcomes, not proven production hangs.
- `secret_scan.json`: current tracked text location-only pattern scan; no Git history, binary, deployed backend or account audit.

See ../../OPTIMIZATION_AUDIT_20261010.md for interpretation, limitations, morning actions and rollback.
