param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$enginePath = (Resolve-Path -LiteralPath $GodotExe).Path
$logsPath = Join-Path $taskRoot 'relatorios-fase20'
New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
$oldSaveDir = $env:AETHEL_TEST_SAVE_DIR
$results = @()
try {
    & $enginePath --headless --path $taskRoot --editor --import --quit --log-file (Join-Path $logsPath 'importacao-final.log') | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Importacao falhou' }
    if (Select-String -LiteralPath (Join-Path $logsPath 'importacao-final.log') -Pattern 'SCRIPT ERROR|Parse Error|Failed to load script' -Quiet) { throw 'Erro de script na importacao' }
    foreach ($testName in @('test_project_integrity','test_items','test_combat','test_gameplay','test_ui_smoke','test_rpg_systems','test_hud_revision','test_consolidation','test_playability','balance_bot')) {
        $env:AETHEL_TEST_SAVE_DIR = Join-Path $logsPath "profiles/$testName"
        New-Item -ItemType Directory -Path $env:AETHEL_TEST_SAVE_DIR -Force | Out-Null
        $logPath = Join-Path $logsPath "$testName-final.log"
        & $enginePath --headless --fixed-fps 60 --path $taskRoot --script "res://tests/$testName.gd" --log-file $logPath | Out-Host
        $testExit = $LASTEXITCODE
        $results += [pscustomobject]@{ Test=$testName; ExitCode=$testExit }
        if ($testExit -ne 0) { throw "Falha em $testName" }
        if (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR|Parse Error|FALHA:|Assertion failed' -Quiet) { throw "Erro registrado por $testName" }
    }
} finally {
    $env:AETHEL_TEST_SAVE_DIR = $oldSaveDir
    $results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logsPath 'results.json')
}
$results | Format-Table
