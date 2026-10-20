$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$destination = Join-Path $taskRoot '.tools'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
$archive = Join-Path $destination 'godot.zip'
$url = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'
Invoke-WebRequest $url -OutFile $archive
$expected = '83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993'
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash -ne $expected) { throw 'Godot archive SHA512 mismatch' }
Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
@{ source=$url; sha512=$expected; version='4.7.2.stable.official.ed1daf0bf' } | ConvertTo-Json | Set-Content (Join-Path $destination 'engine-provenance.json')
