param(
  [Parameter(Mandatory=$true)][ValidateSet('codex','claude')][string]$Role,
  [int]$IntervalSeconds = 60
)
$ErrorActionPreference = 'Stop'
Set-Location (Resolve-Path (Join-Path $PSScriptRoot '..'))
Write-Host "Safe sync watcher for $Role (Ctrl+C to stop). This does NOT run an AI agent."
while ($true) {
  & python scripts/agent_sync.py --role $Role
  if ($LASTEXITCODE -eq 3) { Write-Warning 'Merge conflict with main: resolve deliberately.' }
  Start-Sleep -Seconds ([Math]::Max(30,$IntervalSeconds))
}
