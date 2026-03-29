## Operations Without Skills

Some stack operations are not fully covered by skills — use direct commands
when a skill doesn't apply (e.g., single quick reorder, one-off reword):

- **Reorder commits:** `git move -s <src> -d <dest>` (prefer `/stack-plan` for multi-commit reorders)
- **Reword a message:** `git reword <commit>`
- **Squash commits:** `git move` + manual amend

See `references/philosophy.md` and `references/git-branchless.md` for
full command reference, revsets, and tool selection guidance.
