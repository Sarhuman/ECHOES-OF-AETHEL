param([Parameter(Mandatory=$true)][string]$GodotExe)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'tools/build_windows.ps1') -GodotExe $GodotExe
