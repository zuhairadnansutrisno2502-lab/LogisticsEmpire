# Setup Status — Claude owns preparation on Laptop 2

Status legend: DONE / BLOCKED / WAITING_FOR_USER / NOT_TESTED. Last updated 2026-11-04 by Claude (Laptop 2, macOS).

Repo: https://github.com/zuhairadnansutrisno2502-lab/LogisticsEmpire (private)

| Item | Status | Evidence / next action |
|---|---|---|
| Laptop 2 preflight | DONE | macOS (no PowerShell; ran equivalent shell checks). git 2.55.0, gh 2.101.0, python 3.9.6, Homebrew 7.0.4, Rokit toolchain pinned in `rokit.toml`: rojo 7.7.0, selene 0.31.0, stylua 2.5.2, lune 0.10.5. `scripts/test_project.py` 3/3 OK, project JSON parses, `rojo build` OK. |
| GitHub authentication | DONE | `gh auth status`: `zuhairadnansutrisno2502-lab` (keyring), scopes `repo, workflow, read:org, gist`. Repo-local git identity uses the account's noreply email. |
| Private repository and branches | DONE | Created with `gh repo create --private` after verifying it did not exist. `git ls-remote origin`: `main`, `visual/codex`, `systems/claude` all present. Labels: claude, codex, integration, setup, api-change, blocked. PR template added. |
| GitHub CI | BLOCKED | `validate.yml` is on `main` and the workflow is `active`, but GitHub starts **no runs** (0 runs after PR #2 opened and reopened; only a non-Actions check suite appears). Likely account-level Actions restriction (billing/spending limit or new-account limit). Owner: check https://github.com/settings/billing and the repo's Actions tab. Meanwhile the three jobs pass when run locally on PR #2 (`ownership`, `project-validation`, `python-tests`). |
| PR protections | BLOCKED | `PUT branches/main/protection` → HTTP 403 "Upgrade to GitHub Pro or make this repository public". Not made public. "No direct push to main / PR + green checks before merge" is a team rule until Pro is enabled. |
| Laptop 1 Codex onboarding | DONE | `docs/LAPTOP1_CODEX_ONBOARDING.md`; handoff issue #1 (labels setup, codex). Laptop 1 still has to `gh auth login` + clone (Codex's own step). |
| Rojo integrator on Laptop 2 | DONE (local) | Integrator checkout = git worktree `~/Projects/LogisticsEmpire-integrator` on `main`; dev work in `~/Projects/LogisticsEmpire` on `systems/claude`. `scripts/integrator_sync.sh --serve` → `rojo serve` 7.7.0 on localhost:34872, `/api/rojo` responds. Runs only while that process is alive. |
| Roblox Studio Team Create and plugin | WAITING_FOR_USER | Studio installed, `RojoManagedPlugin.rbxm` present, Studio MCP connected. No experience named Logistics Empire in Studio's recent list, so the shared Team Create place is unknown. Owner: open the existing experience, enable Team Create (Collaborate), invite Laptop 1's Roblox account, then click Connect in the Rojo plugin (localhost:34872). Rojo writes only `ReplicatedStorage.Shared`, `ServerScriptService.LogisticsServer`, `StarterPlayer.StarterPlayerScripts.LogisticsClient`. |
| End-to-end Studio smoke test | NOT_TESTED | Needs a place open in Studio. Local test copy built at `~/Projects/LogisticsEmpire/LogisticsEmpire_localtest.rbxlx` (gitignored, from `systems/claude`). Background control could not reach Studio's file dialog while a full-screen app is active. |

## Real-time two-agent model
Both laptops open the **same Team Create experience** in Studio. Workspace/3D edits sync live through Team Create. Scripts flow `branch → PR → main → Laptop 2 Rojo → Studio`, so only one machine writes code into the place. Codex must not run `rojo serve` against it.

## Integrator commands (Laptop 2, macOS)
```
cd ~/Projects/LogisticsEmpire-integrator && scripts/integrator_sync.sh --serve   # ff-only main, checks, rojo serve
cd ~/Projects/LogisticsEmpire && python3 scripts/agent_sync.py --role claude      # safe ff of systems/claude
```

Do not mark DONE without observed evidence.
