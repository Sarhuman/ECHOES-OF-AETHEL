param([string]$Executable = (Join-Path $PSScriptRoot '../teste-fase20/EchoesOfAethel-Fase25.exe'))
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$logsPath = Join-Path $taskRoot 'relatorios-fase20'
New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
$oldSaveDir = $env:AETHEL_TEST_SAVE_DIR
try {
    $env:AETHEL_TEST_SAVE_DIR = Join-Path $logsPath ('profiles/export-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $env:AETHEL_TEST_SAVE_DIR -Force | Out-Null
    $logPath = Join-Path $logsPath 'release-smoke-final.log'
    $exePath = (Resolve-Path -LiteralPath $Executable).Path
    $process = Start-Process -FilePath $exePath -ArgumentList @('--headless', '--fixed-fps', '60', '--quit-after', '600', '--log-file', ('"' + $logPath + '"'), '--', '--verify-build') -WorkingDirectory (Split-Path -Parent $exePath) -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'Windows executable smoke timed out' }
    $process.Refresh()
    if ($process.ExitCode -ne 0) { throw 'Windows executable smoke failed' }
    $log = Get-Content -LiteralPath $logPath -Raw
    if ($log -notmatch 'SMOKE MENU READY' -or $log -notmatch 'BUILD SMOKE: 21 checks, 0 failures' -or $log -match 'SCRIPT ERROR|Parse Error|FALHA:') {
        throw 'Windows executable did not finish the gameplay smoke checks'
    }
} finally { $env:AETHEL_TEST_SAVE_DIR = $oldSaveDir }
