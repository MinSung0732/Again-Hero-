# Again, Hero? 로컬 테스트 매치 서버 실행기 (더블클릭: tools\localtest_server.cmd)
# - Godot 콘솔 실행 파일로 --localtest 서버를 띄우고, 접속 주소와 입장 코드를 크게 보여 준다.
# - 입장 코드는 클립보드에 자동 복사된다. 이 창을 닫으면 서버도 종료된다.
# Godot 위치: 환경 변수 AGAIN_HERO_GODOT, 없으면 저장소 상위 폴더들에서 Godot_v*_console.exe 를 찾는다.
param([int]$Port = 24840)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot

$godot = $env:AGAIN_HERO_GODOT
if (-not $godot -or -not (Test-Path $godot)) {
    $search = $repo
    for ($i = 0; $i -lt 3 -and -not $godot; $i++) {
        $search = Split-Path -Parent $search
        $found = Get-ChildItem -Path $search -Filter 'Godot_v*_console.exe' -File -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending | Select-Object -First 1
        if ($found) { $godot = $found.FullName }
    }
}
if (-not $godot -or -not (Test-Path $godot)) {
    Write-Host 'Godot 콘솔 실행 파일(Godot_v*_console.exe)을 찾지 못했습니다.' -ForegroundColor Red
    Write-Host '환경 변수 AGAIN_HERO_GODOT 에 전체 경로를 지정하거나, 저장소 상위 폴더에 두세요.'
    exit 1
}

$env:AGAIN_HERO_PORT = "$Port"
$address = "ws://127.0.0.1:$Port"
$host.UI.RawUI.WindowTitle = "Again-Hero 테스트 서버 ($address)"
Write-Host "Godot : $godot"
Write-Host "게임  : $repo"
Write-Host '서버를 시작하는 중...'

$info = New-Object System.Diagnostics.ProcessStartInfo
$info.FileName = $godot
$info.Arguments = "--headless --path `"$repo`" --script res://src/online/server_main.gd -- --localtest"
$info.UseShellExecute = $false
$info.RedirectStandardOutput = $true
$info.RedirectStandardError = $true
$info.StandardOutputEncoding = [System.Text.Encoding]::UTF8
$process = [System.Diagnostics.Process]::Start($info)
# stderr is drained in the background so a full pipe never blocks the server.
$null = $process.StandardError.ReadToEndAsync()

try {
    while (-not $process.HasExited) {
        $line = $process.StandardOutput.ReadLine()
        if ($null -eq $line) { break }
        if ($line -match 'LOCALTEST invitation code:\s*([0-9a-fA-F]+)') {
            $code = $Matches[1]
            try { Set-Clipboard -Value $code } catch {}
            Write-Host ''
            Write-Host '==================================================' -ForegroundColor Yellow
            Write-Host '  테스트 서버가 열렸습니다' -ForegroundColor Green
            Write-Host "  접속 주소 : $address" -ForegroundColor Cyan
            Write-Host "  입장 코드 : $code" -ForegroundColor Cyan
            Write-Host '  (입장 코드는 클립보드에 복사됨 - 게임에 Ctrl+V)' -ForegroundColor Gray
            Write-Host '  이 창을 닫으면 서버가 종료됩니다.' -ForegroundColor Gray
            Write-Host '==================================================' -ForegroundColor Yellow
            Write-Host ''
        } elseif ($line -match 'ready port=') {
            Write-Host $line -ForegroundColor Green
        } elseif ($line -match 'ERROR|error') {
            Write-Host $line -ForegroundColor Red
        }
    }
} finally {
    if (-not $process.HasExited) { $process.Kill() }
}
Write-Host "서버가 종료되었습니다 (exit code $($process.ExitCode))." -ForegroundColor Yellow
