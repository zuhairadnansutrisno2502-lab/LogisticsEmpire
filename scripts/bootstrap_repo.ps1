param([Parameter(Mandatory=$true)][string]$RepoUrl)
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
if (-not (Test-Path '.git')) { git init; if ($LASTEXITCODE -ne 0) { throw 'git init failed' } }
git branch -M main
if ($LASTEXITCODE -ne 0) { throw 'branch failed' }
git add .
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { git commit -m 'Initialize Logistics Empire dual-agent starter'; if ($LASTEXITCODE -ne 0) { throw 'Commit failed. Configure git user first.' } }
$remote = git remote
if ($remote -contains 'origin') { throw 'origin already exists: inspect remote before changing it' }
git remote add origin $RepoUrl
if ($LASTEXITCODE -ne 0) { throw 'remote add failed' }
git push -u origin main
if ($LASTEXITCODE -ne 0) { throw 'Push failed. Authenticate GitHub and verify empty repository.' }
foreach ($branch in @('visual/codex','systems/claude')) {
  git branch $branch main
  if ($LASTEXITCODE -ne 0) { throw "Create branch $branch failed" }
  git push -u origin $branch
  if ($LASTEXITCODE -ne 0) { throw "Push branch $branch failed" }
}
Write-Host 'Bootstrap complete. Configure GitHub branch protection and Roblox Team Create manually.'
