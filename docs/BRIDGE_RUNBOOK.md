> **Setup responsibility:** Claude Code Opus on Laptop 2 executes `docs/CLAUDE_SETUP_ORCHESTRATOR.md` before backend work. Laptop 2 is the default sole integrator. Manual steps below are fallback/reference, not tasks to delegate to Codex.

# Two-Laptop Bridge Runbook

## Architecture
Laptop 1 Codex (`visual/codex`) and Laptop 2 Claude (`systems/claude`) use GitHub as shared asynchronous source of truth. Agents **do not share a filesystem** and **do not automatically see each other's uncommitted edits**. CI validates PRs. An approved integrator merges passing PRs to `main`. A single Rojo integration machine syncs `main` to the **existing** Roblox Studio Team Create experience. Team Create handles Studio collaboration, but does not grant agent access by itself.

## Initial setup
1. Install Git, Python 3.10+, Roblox Studio, Rojo CLI and matching Studio plugin on integration laptop; GitHub CLI `gh` optional but recommended. Authenticate `git` and `gh` securely, no credentials in repo.
2. Create **private empty** `LogisticsEmpire` repository on GitHub; upload starter to `main` using `scripts/bootstrap_repo.ps1` on Windows or manual Git steps. Configure branch protection: require PR, required `ownership`, `project-validation`, `python-tests` checks, restrict direct push, require review. For strict cross-agent review, require an independent human/authorized reviewer because self-approval may not count.
3. Create `visual/codex` and `systems/claude` from `main`; clone on respective laptops; checkout role branch.
4. Roblox owner enables Team Create and invites approved accounts with Edit access to **existing experience**. Back up existing place. Verify Rojo mappings do not collide with existing objects. Never publish from this automation.
5. Integrator opens existing Studio place, connects Rojo plugin to the integration laptop Rojo server, verifies mapping on a **test copy or safe staging place** before applying to production place. Production publish requires human approval.

## Automation model
- `scripts/agent_sync.py --role codex|claude`: fetch `origin/main` and update the clean role branch by fast-forward, or by a conflict-free merge when both sides moved; on any conflict it aborts and exits 3. It never pushes or touches other branches.
- `scripts/agent_news.py --role codex|claude`: start-of-task briefing for agents: new merges on `main`, files the other side changed that you must read, branch sync (via agent_sync), open PRs and `api-change` issues.
- `scripts/agent_watch.ps1 -Role codex|claude`: optional periodic safe sync every 60 seconds; only if no local edits. This does **not** run agents or trigger AI prompts; agents remain responsible for commits, PRs and implementation.
- `scripts/integrator_sync.ps1`: on integration machine, pull fast-forward-only `main`, verify JSON/ownership-related project checks, start Rojo server. Operator must open Roblox Studio and connect plugin. Do not launch this on both laptops for same tree.
- `.github/workflows/validate.yml`: PR checks; **no automatic merge or Roblox publish**. GitHub Actions cannot connect to a local Studio Team Create session by itself.

## PR handoff protocol
1. Claude documents schema in `docs/API_CONTRACT.md`; Codex builds mock adapter matching schema.
2. Each agent pushes a small PR with: changes, API impact, self-critique, test evidence, screenshots where relevant, risks, rollback.
3. CI checks owner paths and syntax; cross-review agent checks integration impact. A human/integrator approves and merges passing PRs.
4. Integrator fast-forward pulls `main` and syncs via single Rojo process. Perform Studio playtest, inspect output and visual parity, file a bug issue for failed behavior.
5. Each agent periodically syncs integrated `main` safely. If merge conflict occurs, stop and resolve with review, never overwrite silently.

## Why not true zero-latency?
GitHub commit/PR/merge introduces delay; Rojo watches local files but is not a cross-laptop live collaboration protocol. Team Create synchronizes Studio edits, not agent code branches. Avoid auto-merge untested changes and two Rojo writers. A safe near-real-time workflow means frequent small PRs and a single integration path, not simultaneous writes to the same instance tree.

## Troubleshooting
- Missing repository/remote: run bootstrap after creating GitHub repo.
- Diverged branches: sync script refuses to merge; open PR/rebase deliberately with clean backup.
- Studio not updating: verify `rojo serve`, plugin connection, existing place, correct mappings and whether PR was merged.
- Agent cannot control Studio: confirm actual authorized local tooling; prompt alone cannot provide Studio permissions.
- DataStore in Studio: use safe test environment; don't enable production API access casually.
