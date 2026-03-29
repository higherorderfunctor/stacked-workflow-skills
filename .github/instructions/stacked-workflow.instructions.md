---
applyTo: "**"
---

## Dev-Only Skills

These skills are for developing this repo, not distributed to consumers:

<!-- dprint-ignore -->
| Skill              | What it does                                                                                              |
| ------------------ | --------------------------------------------------------------------------------------------------------- |
| `/index-repo-docs` | Fetch and distill a repo's wiki, docs, and issues into a focused reference doc                            |
| `/repo-review`     | Multi-perspective repo review with 6 specialized reviewers, decision tracking, and human-approved changes |

## Operations Without Skills

Some stack operations are not fully covered by skills — use direct commands
when a skill doesn't apply (e.g., single quick reorder, one-off reword):

- **Reorder commits:** `git move -s <src> -d <dest>` (prefer `/stack-plan` for multi-commit reorders)
- **Reword a message:** `git reword <commit>`
- **Squash commits:** `git move` + manual amend

See `references/philosophy.md` and `references/git-branchless.md` for
full command reference, revsets, and tool selection guidance.

## Skill Routing — MANDATORY

When the user is working with stacked commits, use the appropriate skill
instead of running commands manually via Bash.

<!-- dprint-ignore -->
| Operation                                               | Skill            | Use INSTEAD of                                                 |
| ------------------------------------------------------- | ---------------- | -------------------------------------------------------------- |
| Audit stack quality before restructure                  | `/stack-summary` | Manual `git log` inspection                                    |
| Commit uncommitted work as an atomic stack              | `/stack-plan`    | `git add -A && git commit` (single monolithic commit)          |
| Edit earlier commit (content moves, structural changes) | `/stack-fix`     | Manual `git prev` + edit + `git amend` + `git restack --merge` |
| Fix lines in earlier commit                             | `/stack-fix`     | `git absorb`, `git commit --fixup`, manual checkout + amend    |
| Plan and build a commit stack from a description        | `/stack-plan`    | Ad-hoc `git record` / `git commit` without a plan              |
| Push stack for review                                   | `/stack-submit`  | Manual `git sync` + `git submit` + `gh pr create`              |
| Restructure/reorder existing commits                    | `/stack-plan`    | `git rebase -i`, `git reset --soft`, `git move` sequences      |
| Split a large commit                                    | `/stack-split`   | `git rebase -i` + edit, `git reset HEAD^`                      |
| Test across stack                                       | `/stack-test`    | Manual `git test run` or looping `git checkout` + test         |

**RULE: Before running any git-branchless, git-absorb, or git-revise command
via Bash, check if a skill covers the operation.** Skills include pre-flight
checks, dry-run previews, conflict guidance, and post-operation verification
that manual commands miss.
