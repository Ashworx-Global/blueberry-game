---
description: Commit working-tree changes as grouped GPG-signed semantic commits
---

Load the `commit-changes` skill and follow it exactly: inspect the working
tree, group similar files into logical commits, and create one GPG-signed
semantic commit per group (`<type>(<scope>): <subject>`).

Hint for this run: `$ARGUMENTS` (empty means commit everything appropriate;
otherwise limit scope to what the hint names).

Rules:
- Refuse to commit on `main` — agree a `feat/*` branch first.
- Sign every commit (`-S`); verify with `git log -1 --show-signature`.
  Never fall back to an unsigned commit; on signing failure, stop and ask.
- Leave `.godot/`, secrets, and unrelated files uncommitted; report them.
- Push the branch with `git push -u origin <branch>` (never to `main`,
  never force-push); skip only if the hint says "no push".
- Report SHAs, files per commit, anything left uncommitted, and the push result.
