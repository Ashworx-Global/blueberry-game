# Blue Berry — opencode Agent Instructions

This file is opencode's project entry point. It shares the same contract as every other agent through:

- `../AI_SPEC.md` — cross-AI project rules and documentation policy.
- `../AGENTS.md` — root agent instructions.
- `../SPEC.md` — canonical gameplay and implementation spec.
- `../MEMORY.md` — runbook, Godot troubleshooting, verification.
- `../PLAN.md` — roadmap and tasks.

If anything here conflicts with `../SPEC.md`, follow `../SPEC.md` and update the stale doc in the same change.

---

## OpenCode notes

- Project root = repo root. Run Godot with `--path <repo>` (use `--path .` from the repo root); see `../MEMORY.md` §1 for per-OS executable paths.
- Detailed scene/script contracts live in `../MEMORY.md`; gameplay truth in `../SPEC.md`; tasks in `../PLAN.md`. Do not duplicate them here — pointers only, so all agents share one contract.
- For commits, use the local skill `gpg-signed-commits` at `$HOME/.config/opencode/skills/gpg-signed-commits/SKILL.md`: commit with `git commit -S`, verify with `git log -1 --show-signature`, and never fall back to an unsigned commit.
- When adding features, tasks, or new files, sync `../SPEC.md`, `../MEMORY.md`, and `../PLAN.md` per `../AI_SPEC.md` Documentation Policy, then mention the docs updated.
