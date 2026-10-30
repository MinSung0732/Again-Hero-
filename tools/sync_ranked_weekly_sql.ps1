# Regenerate the SQL seed after changing ranked_badges.json; run from any directory.
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$data = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'src/data/ranked_badges.json') | ConvertFrom-Json
$sqlPath = Join-Path $root 'supabase/migrations/20261030120000_ranked_weekly_settlement.sql'
$thresholds = @{}
foreach ($entry in $data.mmr_thresholds) { $thresholds[$entry.id] = [int]$entry.mmr }
$rows = foreach ($entry in $data.weekly_rewards.PSObject.Properties) {
    $id = $entry.Name
    $resetId = if ($id -in @('hero','demon_lord')) { $data.weekly_reset_high_tier } else { ($id -split '_')[0] + '_1' }
    $reset = [Math]::Max([int]$data.initial_mmr, $thresholds[$resetId])
    "('$id',$reset,$($entry.Value.demon_token),$($entry.Value.hero_token))"
}
$seed = 'insert into private.ranked_reward_tiers(tier_id,reset_mmr,demon_token,hero_token) values' + "`n " + ($rows -join ",`n ") + ';'
$encoding = [Text.UTF8Encoding]::new($false)
$sql = [IO.File]::ReadAllText($sqlPath, $encoding)
$sql = [regex]::Replace($sql, '(?s)(-- BEGIN GENERATED RANKED REWARDS\r?\n).*?(-- END GENERATED RANKED REWARDS)', ('$1' + $seed + "`n" + '$2'))
[IO.File]::WriteAllText($sqlPath, $sql, $encoding)