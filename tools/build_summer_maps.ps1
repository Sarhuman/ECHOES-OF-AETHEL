param(
    [Parameter(Mandatory=$true)][string]$SummerExe,
    [ValidateSet('ISOLATED','VIGILIA')][string]$Mode='ISOLATED'
)
$ErrorActionPreference='Stop'
$taskRoot=Split-Path -Parent $PSScriptRoot
$sandbox=Join-Path $taskRoot '.tools/summer273'
$output=Join-Path $sandbox 'art/imported/vigilia'
$enginePath=(Resolve-Path -LiteralPath $SummerExe).Path
if($Mode -eq 'VIGILIA') {
    $proof=Join-Path $taskRoot 'docs/evidence/fase27-3-isolated.json'
    if(-not(Test-Path -LiteralPath $proof) -or -not(Get-Content -LiteralPath $proof -Raw | ConvertFrom-Json).passed) { throw 'Validate the isolated test in official Godot before authoring Vigilia' }
    $proofData=Get-Content -LiteralPath $proof -Raw | ConvertFrom-Json
    if($proofData.metrics.headless -or $proofData.scene_sha256 -ne (Get-FileHash -LiteralPath (Join-Path $taskRoot 'art/imported/vigilia/integration_test.tscn') -Algorithm SHA256).Hash.ToLower()) { throw 'Graphical proof must match the current isolated scene' }
}
New-Item -ItemType Directory -Force -Path $sandbox,$output | Out-Null
@'
config_version=5
[application]
config/name="Aethel Summer isolated authoring"
[rendering]
renderer/rendering_method="gl_compatibility"
'@ | Set-Content -LiteralPath (Join-Path $sandbox 'project.godot')
Copy-Item -LiteralPath (Join-Path $taskRoot 'art/source/vigilia/build_summer_scene.gd') -Destination (Join-Path $sandbox 'build.gd')
Copy-Item -LiteralPath (Join-Path $taskRoot 'art/source/vigilia/layout.json') -Destination (Join-Path $sandbox 'layout.json')
$stdout=Join-Path $sandbox ('summer-'+$Mode+'-stdout.log')
$stderr=Join-Path $sandbox ('summer-'+$Mode+'-stderr.log')
$arguments=@('--headless','--path',('"'+$sandbox+'"'),'--script','res://build.gd','--',$Mode)
$process=Start-Process -FilePath $enginePath -ArgumentList $arguments -WorkingDirectory $sandbox -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru
if(-not $process.WaitForExit(60000)) { $process.Kill(); throw 'Summer authoring timeout; no scene accepted' }
$process.Refresh()
$log=(Get-Content -LiteralPath $stdout -Raw)+(Get-Content -LiteralPath $stderr -Raw)
if($process.ExitCode -ne 0 -or $log -notmatch 'SUMMER AUTHORING: .*"success":true' -or $log -match 'SCRIPT ERROR|Parse Error|Failed to load script') { throw ('Summer authoring failed: '+$log) }
$destination=Join-Path $taskRoot 'art/imported/vigilia'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
Copy-Item -Path (Join-Path $output '*') -Destination $destination -Recurse -Force
$record=@{ engine=(Get-Content -LiteralPath $stdout -Raw).Trim(); executableSha256=(Get-FileHash -LiteralPath $enginePath -Algorithm SHA256).Hash.ToLower(); mode=$Mode; editorVersion='0.7.3'; generated=(Get-ChildItem -LiteralPath $destination -File -Recurse | ForEach-Object { @{file=$_.Name;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLower()} }) }
$record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $taskRoot ('docs/evidence/fase27-3-summer-'+$Mode.ToLower()+'.json'))
Write-Output ('SUMMER AUTHORING VERIFIED: '+$Mode)
