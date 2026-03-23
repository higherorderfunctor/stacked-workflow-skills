# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with
code in this repository.

## Project Overview

stacked-workflow-skills is a collection of SKILL.md files and reference docs
for stacked commit workflows using git-branchless, git-absorb, and git-revise.
The skills automate common stack operations (plan, fix, split, submit, test)
and work with any tool that supports SKILL.md (Claude Code, Kiro, Copilot).

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**Types:** `feat`, `fix`, `refactor`, `docs`, `chore`, `build`, `ci`, `style`,
`perf`, `test`

**Scopes** (optional but encouraged): `skills`, `references`, `flake`, `dev`,
or a specific skill name (e.g., `stack-fix`, `stack-split`)

Keep descriptions lowercase, imperative mood, no trailing period.

## Build & Dev Commands

```bash
nix develop          # Enter devShell (git-branchless, git-absorb, git-revise)
nix fmt              # Format all Nix files with alejandra
nix flake check      # Validate flake and run checks
```

## Flake Structure

- **flake.nix** — nixpkgs input, devShell with stacked workflow tools, formatter
- **skills/** — SKILL.md files for each stack operation
- **references/** — distilled reference docs for git-branchless, git-absorb, git-revise

## Skill Routing — MANDATORY

When the user is working with stacked commits, use the appropriate skill
instead of running commands manually via Bash.

<!-- dprint-ignore -->
| Operation | Skill | Use INSTEAD of |
|-----------|-------|----------------|
| Fix lines in earlier commit | `/stack-fix` | `git absorb`, `git commit --fixup`, manual checkout + amend |
| Edit earlier commit (content moves, structural changes) | `/stack-fix` | Manual `git prev` + edit + `git amend` + `git restack --merge` |
| Split a large commit | `/stack-split` | `git rebase -i` + edit, `git reset HEAD^` |
| Plan and build a commit stack from a description | `/stack-plan` | Ad-hoc `git record` / `git commit` without a plan |
| Restructure/reorder existing commits | `/stack-plan` | `git rebase -i`, `git reset --soft`, `git move` sequences |
| Commit uncommitted work as an atomic stack | `/stack-plan` | `git add -A && git commit` (single monolithic commit) |
| Push stack for review | `/stack-submit` | Manual `git sync` + `git submit` |
| Test across stack | `/stack-test` | Manual `git test run` or looping `git checkout` + test |

**RULE: Before running any git-branchless, git-absorb, or git-revise command
via Bash, check if a skill covers the operation.** Skills include pre-flight
checks, dry-run previews, conflict guidance, and post-operation verification
that manual commands miss.

## Stack Modification Tool Selection

Before modifying a stack, identify the operation and select the right tool.
Not every operation has a skill — some are best done with direct commands.

<!-- dprint-ignore -->
| Operation | First choice | Fallback | Why |
|-----------|-------------|----------|-----|
| Fix lines in earlier commit | `/stack-fix` | `git absorb --and-rebase` | skill adds dry-run preview |
| Move content between commits | `/stack-fix` (Path B) | checkout + `git amend` | skill guides conflict resolution |
| Reorder commits | `git move -s <src> -d <dest>` | `git revise -i` | in-memory, handles subtrees |
| Reword a message | `git reword <commit>` | `git revise <commit>` | no checkout needed |
| Split a commit | `/stack-split` | `git split`, `git rebase -i` + edit | skill handles full workflow |
| Restructure entire stack | `/stack-plan` | `git reset --soft main` + recommit | skill handles full workflow |
| Squash commits | `git move` + manual amend | N/A | `git move -F` panics on conflicts |
| Bulk insert/reorder (3+ changes) | batch-at-tip + scripted rebase | individual `git record -I` | avoids conflict cascades |

See `references/philosophy.md` § Bulk Stack Modification for the full pattern.

## Key Commands

**Navigation:** `git sl` (smartlog), `git next`/`git prev` (`-a` all,
`-b` branch), `git sw -i` (fuzzy switch)

**Committing:** `git record -m "msg"`, `git record -i` (interactive),
`git record -I` (insert mid-stack), `git amend` (amend + auto-restack)

**Rewriting:** `git reword <commit>`, `git move -s <src> -d <dest>`,
`git split`, `git restack`

**Stack Management:** `git sync --pull`, `git submit -c`,
`git hide -r <hash>`, `git undo` (`-i` interactive)

**Testing:** `git test run -x '<cmd>'` (`--jobs 0` parallel),
`git test fix -x '<fmt>'`

See `references/git-branchless.md` for full details.

## Revset Quick Reference

<!-- dprint-ignore -->
| Revset | Matches |
|--------|---------|
| `stack()` | Current stack |
| `draft()` | All draft (non-public) commits |
| `main()` | Tip of main branch |
| `branches()` | Commits with branches |
| `children(x)` / `parents(x)` | Graph traversal |
| `paths.changed(pattern)` | Commits touching files |
| `message(pattern)` | Commits matching message |
| `x::y` | Range (descendants of x AND ancestors of y) |
| `x % y` | Only (ancestors of x NOT ancestors of y) |

See `references/git-branchless.md` for the full revset language.

## Initialization

Before using any branchless commands in a repo, check if initialized:

```bash
if [ ! -d ".git/branchless" ]; then git branchless init; fi
```

All skills include this as a pre-flight check. Run it before the first
branchless command in any session.

## Code Quality

Permissions for git-branchless, git-absorb, and git-revise commands are
pre-approved in `.claude/settings.json`. Reference docs in `references/` are
also pre-approved for reading.

## Coding Standards

### Bash

All shell scripts must use full strict mode:

```bash
#!/usr/bin/env bash
set -euETo pipefail
shopt -s inherit_errexit 2>/dev/null || :
```

### Ordering

Keep entries sorted alphabetically within categorical groups. Use section
headers for readability, sort entries within each group.

### DRY Principle

Never duplicate logic, configuration, or patterns. When the same thing appears
twice, extract it. Skills reference shared docs in `references/` rather than
duplicating content.
