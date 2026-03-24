---
applyTo: "**"
---

# Stacked Workflow Skill Routing

When working with stacked commits, invoke the appropriate skill instead of
running git commands directly.

| Operation | Skill | Use INSTEAD of |
|-----------|-------|----------------|
| Audit stack quality before restructure | `/stack-summary` | Manual `git log` inspection |
| Commit uncommitted work as an atomic stack | `/stack-plan` | `git add -A && git commit` (single monolithic commit) |
| Edit earlier commit (content moves, structural changes) | `/stack-fix` | Manual `git prev` + edit + `git amend` + `git restack --merge` |
| Fix lines in earlier commit | `/stack-fix` | `git absorb`, `git commit --fixup`, manual checkout + amend |
| Plan and build a commit stack from a description | `/stack-plan` | Ad-hoc `git record` / `git commit` without a plan |
| Push stack for review | `/stack-submit` | Manual `git sync` + `git submit` + `gh pr create` |
| Restructure/reorder existing commits | `/stack-plan` | `git rebase -i`, `git reset --soft`, `git move` sequences |
| Split a large commit | `/stack-split` | `git rebase -i` + edit, `git reset HEAD^` |
| Test across stack | `/stack-test` | Manual `git test run` or looping `git checkout` + test |

**Always check if a skill covers the operation before running raw
git-branchless, git-absorb, or git-revise commands.**