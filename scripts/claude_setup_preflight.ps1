# Non-destructive environment diagnostics for Claude on Laptop 2.
$ErrorActionPreference = 'Continue'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
Write-Host 'LOGISTICS EMPIRE - LAPTOP 2 PREFLIGHT (read-only)'
foreach ($tool in @('git','gh','python','rojo','winget')) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($cmd) { Write-Host "[FOUND] $tool => $($cmd.Source)" } else { Write-Host "[MISSING] $tool" }
}
if (Get-Command git -ErrorAction SilentlyContinue) {
  git --version
  Write-Host 'Git status:'
  git status --short 2>&1
  Write-Host 'Git remotes:'
  git remote -v 2>&1
  Write-Host 'Git branch:'
  git branch --show-current 2>&1
}
if (Get-Command gh -ErrorAction SilentlyContinue) {
  Write-Host 'GitHub authentication:'
  gh auth status 2>&1
}
if (Get-Command python -ErrorAction SilentlyContinue) {
  python --version
  python scripts/test_project.py
  python -m json.tool default.project.json | Out-Null
  if ($LASTEXITCODE -eq 0) { Write-Host '[PASS] Rojo project JSON parses' }
}
if (Get-Command rojo -ErrorAction SilentlyContinue) { rojo --version }
Write-Host 'No changes made by this preflight.'
