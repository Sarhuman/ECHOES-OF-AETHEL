param([Parameter(Mandatory=$true)][string]$GodotExe, [switch]$SkipTests)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$enginePath = (Resolve-Path -LiteralPath $GodotExe).Path
$outputPath = Join-Path $taskRoot 'teste-fase20'
$logsPath = Join-Path $taskRoot 'relatorios-fase20'
$templatePath = Join-Path $taskRoot '.tools/templates/windows_release_x86_64.exe'
if (-not (Test-Path -LiteralPath $templatePath)) { throw 'Template ausente. Execute python tools/fetch_windows_template.py.' }
New-Item -ItemType Directory -Path $outputPath,$logsPath -Force | Out-Null
if (-not $SkipTests) { & (Join-Path $PSScriptRoot 'test.ps1') -GodotExe $enginePath }
& $enginePath --headless --path $taskRoot --export-release 'Windows Desktop' (Join-Path $outputPath 'EchoesOfAethel-Fase20.exe') --log-file (Join-Path $logsPath 'exportacao-release.log') | Out-Host
if ($LASTEXITCODE -ne 0) { throw 'Exportacao Windows falhou' }
$exportLog = Get-Content -LiteralPath (Join-Path $logsPath 'exportacao-release.log') -Raw
if ($exportLog -match 'SCRIPT ERROR|Parse Error|Export failed') { throw 'Erro na exportacao' }
Get-FileHash -LiteralPath (Join-Path $outputPath 'EchoesOfAethel-Fase20.exe'),(Join-Path $outputPath 'EchoesOfAethel-Fase20.pck') -Algorithm SHA256 | Format-List | Out-File (Join-Path $outputPath 'SHA256.txt')
Write-Host "Exportado em $outputPath"
