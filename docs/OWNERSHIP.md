# Ownership and Change Protocol

| Path | Owner |
| --- | --- |
| `src/client/**`, `src/shared/VisualConfig/**`, `assets/**` | Codex |
| `src/server/**`, `src/shared/Contracts/**`, `src/shared/Types/**`, `tests/**`, `docs/API_CONTRACT.md` | Claude |
| `docs/quality/CODEX_REVIEW.md` | Codex |
| `docs/quality/CLAUDE_REVIEW.md` | Claude |
| `.github/**`, `scripts/**`, `default.project.json`, `AGENTS.md`, `docs/BRIDGE_RUNBOOK.md`, `docs/PROJECT_SPEC.md` | Integrator only |

`docs/PROGRESS.md` is integration-owned. Agents post progress in their own quality files and PR descriptions. If another agent needs an interface change, create an Issue with request/response examples; Claude proposes API changes through PR. Codex reviews client compatibility. Integration-owned files require explicit integrator PR approval. PRs touching unauthorized paths fail CI. No direct commits to `main`. No forced pushes.
