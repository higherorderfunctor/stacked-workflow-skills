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
