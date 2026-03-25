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
nix flake check      # Validate flake, formatting, and spelling
```

**Note:** `nix flake check` only includes tracked files; add new files with
`git add` before running it in a dirty git tree.

## Flake Structure

- **flake.nix** — nixpkgs + nvfetcher inputs, overlays, packages, devShell, lib, homeManagerModules
- **.generated/** — pre-generated routing files for Claude, Kiro, Copilot (CI-maintained)
- **docs/decisions/** — MADR-style architecture decision records with confidence scoring
- **home-manager/** — home-manager module for declarative per-user installation
- **INSTALL.md** — installation and routing setup for all platforms and methods
- **references/** — canonical reference docs (symlinked into each skill's `references/`)
- **skills/** — SKILL.md files with per-skill `references/` subdirectories
- **dev/** — dev-only skills (repo-review, index-repo-docs), symlinked into `.claude/skills/`

<!-- Generated from lib/routing-data.nix via `nix eval --raw .#lib.mkClaudeRouting` — keep in sync -->

## Skill Routing — MANDATORY

When the user is working with stacked commits, use the appropriate skill
instead of running commands manually via Bash.

<!-- dprint-ignore -->
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

**RULE: Before running any git-branchless, git-absorb, or git-revise command
via Bash, check if a skill covers the operation.** Skills include pre-flight
checks, dry-run previews, conflict guidance, and post-operation verification
that manual commands miss.

## Dev-Only Skills

These skills are for developing this repo, not distributed to consumers:

<!-- dprint-ignore -->
| Skill | What it does |
|-------|-------------|
| `/index-repo-docs` | Fetch and distill a repo's wiki, docs, and issues into a focused reference doc |
| `/repo-review` | Multi-perspective repo review with 6 specialized reviewers, decision tracking, and human-approved changes |

## Operations Without Skills

Some stack operations are not fully covered by skills — use direct commands
when a skill doesn't apply (e.g., single quick reorder, one-off reword):

- **Reorder commits:** `git move -s <src> -d <dest>` (prefer `/stack-plan` for multi-commit reorders)
- **Reword a message:** `git reword <commit>`
- **Squash commits:** `git move` + manual amend

See `references/philosophy.md` and `references/git-branchless.md` for
full command reference, revsets, and tool selection guidance.

## Continuous Improvement

When working in this repo, be introspective about patterns and failures.
Learnings should be distributed into the skills and references so consumers
benefit — that's the purpose of this package.

1. **Codify into consumer-facing docs** — new gotchas, strategies, or
   patterns go into `references/philosophy.md`, relevant skill files, or
   other reference docs so every consumer gets the improvement
2. **Track gaps** — if a skill is missing guidance that would have prevented
   an error, note it for the user
3. **Codify, don't repeat** — if the same mistake or correction happens twice,
   it belongs in a reference doc, not just in memory

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
