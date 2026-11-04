param([switch]$Serve)
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
if ((git branch --show-current) -ne 'main') { throw 'Integrator must use main branch' }
if (git status --porcelain) { throw 'Working tree must be clean' }
git fetch origin main
if ($LASTEXITCODE -ne 0) { throw 'Fetch failed' }
git merge --ff-only origin/main
if ($LASTEXITCODE -ne 0) { throw 'Main diverged; refusing unsafe merge' }
python -m json.tool default.project.json | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Invalid Rojo JSON' }
if ($Serve) {
  if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) { throw 'Rojo CLI not found; install it first' }
  Write-Host 'Starting Rojo server. Open the EXISTING Roblox Studio experience and connect Rojo plugin manually.'
  rojo serve default.project.json
} else { Write-Host 'Main updated safely. Run with -Serve to start Rojo server.' }
