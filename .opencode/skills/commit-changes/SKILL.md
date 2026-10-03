---
name: commit-changes
description: Group working-tree changes into related GPG-signed commits with semantic messages, then push.
---

# Commit Changes

Turn a dirty working tree into a series of small, related, **GPG-signed**
commits with semantic messages, then push the branch.

## 0. Signing prerequisites (every time)

This skill never creates an unsigned commit. Follow the `gpg-signed-commits`
skill (`$HOME/.config/opencode/skills/gpg-signed-commits/SKILL.md`):

- Ensure `gpg.program` points at the passphrase wrapper and
  `commit.gpgsign` is `true` (repo + global).
- Sign every commit explicitly: `git commit -S -m "<message>"`
  (`--amend -S`, `--gpg-sign` for rebase, etc.).
- Verify each commit: `git log -1 --show-signature` (expect `Good signature`).
- Never print, echo, or log the `$GPG` passphrase value.
- If signing fails, stop and ask the user — never fall back to unsigned.

## 1. Inspect before staging

```sh
git status --short
git diff --stat
git log --oneline -5
```

Read the actual diffs (`git diff -- <path>`) so groups and messages describe
real changes, not file names. Stage only intended files — never use `git add -A`
blindly.

## 2. Branch guard

`main` is protected (signed commits only, no force-push/deletion, merge via PR):

- If the current branch is `main`, stop and agree a `feat/*` branch name
  with the user first — never commit on `main`, never push to `main`.
- Never force-push. Plain `git push` only.

## 3. Group similar files per commit

Split the working tree into logical commits. Each commit is one idea:

- A scene plus its script (`scenes/Enemy.tscn` + `scripts/enemy.gd`).
- One feature's code together; its docs update alongside only if trivial,
  otherwise a separate `docs:` commit.
- Project docs (`SPEC.md`, `MEMORY.md`, `PLAN.md`, `AGENTS.md`) grouped by
  topic, not lumped with unrelated code.
- Tooling/skill/command files (`.opencode/`, `tools/`) as their own
  `chore:` commit.
- Leave alone and report (do not stage without asking):
  - `.godot/` cache output, secrets, `.env`, credentials.
  - Untracked files the current session did not create (e.g. stray
    `*.import` files from someone else's import run).
  - Unrelated work-in-progress that belongs to a different branch.

Stage each group explicitly by path: `git add <paths...>`.

## 4. Semantic messages

Format (per joshbuchea/semantic-commit-messages):

```
<type>(<scope>): <subject>
```

- `<scope>` is optional but preferred (area: `player`, `enemy`, `docs`,
  `skills`, `parallax`).
- `<subject>`: present tense, lowercase, no trailing period, ≤72 chars.
- Body (optional): explain *why* when the subject is not enough.

Types:

| Type | Use for |
|------|---------|
| `feat` | New gameplay/user-facing feature |
| `fix` | Bug fix (gameplay, crash, parse error) |
| `docs` | `SPEC.md`/`MEMORY.md`/`PLAN.md`/runbook only |
| `style` | Formatting, no logic change |
| `refactor` | Code restructure, no behavior change |
| `test` | Tests, no production change |
| `chore` | Tooling, skills, commands, deps, config |
| `perf` | Performance improvement |
| `revert` | Revert a previous commit |

Good: `feat(player): add hop-cancel during attack recovery`.
Bad: `fixed stuff`, `WIP`, `update`, `feat: Add Hop-Cancel.`

## 5. Commit and verify

One commit per group:

```sh
git add <group paths...>
git commit -S -m "<type>(<scope>): <subject>"
git log -1 --show-signature
git status --short   # confirm the group is gone, nothing extra staged
```

Then report per-commit: SHA + message, files in each. Then push (§6)
and report the push result — not the other way round.

## 6. Push

After all groups are committed and verified:

```sh
git push -u origin <branch>
```

- Only push the current `feat/*` (or other non-`main`) branch. Never push
  to `main` — merging happens via PR.
- Set upstream with `-u` on first push so follow-ups are plain `git push`.
- Never force-push (`--force`, `-f`). If the push is rejected, stop and
  report — do not rebase or rewrite history without asking.
- Skip pushing only when the user says so (e.g. `/commit` hint says
  "no push"); say so in the final report.
