param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$enginePath = (Resolve-Path -LiteralPath $GodotExe).Path
$logsPath = Join-Path $taskRoot 'relatorios-fase20'
New-Item -ItemType Directory -Path $logsPath -Force | Out-Null
$oldSaveDir = $env:AETHEL_TEST_SAVE_DIR
$results = @()
$markers = @{
    test_us01_fix01='FIX01 REGRESSION:'
    test_us01_baseline='US01 BASELINE:'
    test_phase27_gui='PHASE27 GUI:'; test_phase27='PHASE27:'; test_phase26_gui='PHASE26 GUI:'; test_phase26='PHASE26:'; test_phase25='PHASE25:'; test_phase25_gui='PHASE25 GUI:'; test_phase24='PHASE24:'; test_phase24_gui='PHASE24 GUI:'; test_phase23='PHASE23:'; test_phase23_gui='PHASE23 GUI:'
    test_gothic_ui='GOTHIC UI:'; test_project_integrity='PROJECT INTEGRITY:'
    test_items='ITEMS TEST OK'; test_combat='COMBAT TEST OK'; test_gameplay='GAMEPLAY TEST OK'
    test_ui_smoke='UI SMOKE TEST OK'; test_rpg_systems='RPG SYSTEMS TEST OK'; test_hud_revision='HUD REVISION TEST OK'
    test_consolidation='CONSOLIDATION:'; test_playability='PLAYABILITY:'; balance_bot='VITÓRIAS: 10/10'
}
try {
    & $enginePath --headless --path $taskRoot --editor --import --quit --log-file (Join-Path $logsPath 'importacao-final.log') | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'Importacao falhou' }
    if (Select-String -LiteralPath (Join-Path $logsPath 'importacao-final.log') -Pattern 'SCRIPT ERROR|Parse Error|Failed to load script' -Quiet) { throw 'Erro de script na importacao' }
    $graphLog = Join-Path $logsPath 'region-graph-final.log'
    & $enginePath --headless --path $taskRoot --script res://tools/validate_regions.gd --log-file $graphLog | Out-Host
    if ($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $graphLog -Pattern 'SCRIPT ERROR|Parse Error' -Quiet)) { throw 'Region graph validation failed' }
    foreach ($testName in @('test_us01_fix01','test_us01_baseline','test_phase27_gui','test_phase27','test_phase26_gui','test_phase26','test_phase25','test_phase25_gui','test_phase24','test_phase24_gui','test_phase23','test_phase23_gui','test_gothic_ui','test_project_integrity','test_items','test_combat','test_gameplay','test_ui_smoke','test_rpg_systems','test_hud_revision','test_consolidation','test_playability','balance_bot')) {
        $env:AETHEL_TEST_SAVE_DIR = Join-Path $logsPath "profiles/$testName"
        New-Item -ItemType Directory -Path $env:AETHEL_TEST_SAVE_DIR -Force | Out-Null
        $logPath = Join-Path $logsPath "$testName-final.log"
        & $enginePath --headless --fixed-fps 60 --quit-after 18000 --path $taskRoot --script "res://tests/$testName.gd" --log-file $logPath | Out-Host
        $testExit = $LASTEXITCODE
        $results += [pscustomobject]@{ Test=$testName; ExitCode=$testExit }
        if ($testExit -ne 0) { throw "Falha em $testName" }
        if (Select-String -LiteralPath $logPath -Pattern 'SCRIPT ERROR|Parse Error|FALHA:|Assertion failed' -Quiet) { throw "Erro registrado por $testName" }
        if (-not (Select-String -LiteralPath $logPath -Pattern $markers[$testName] -SimpleMatch -Quiet)) { throw "Teste nao concluiu: $testName" }
    }
} finally {
    $env:AETHEL_TEST_SAVE_DIR = $oldSaveDir
    $results | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $logsPath 'results.json')
}
$results | Format-Table
