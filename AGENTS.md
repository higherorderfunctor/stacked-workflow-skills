# AGENTS.md

Project instructions for AI coding assistants working in this repository.
Read by Claude Code, Kiro, GitHub Copilot, Codex, and other tools that
support the [AGENTS.md standard](https://agents.md).

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
agnix .              # Lint AI agent config files
```

**Note:** `nix flake check` only includes tracked files; add new files with
`git add` before running it in a dirty git tree.

## Flake Structure

- **.generated/** — pre-generated routing files for Claude, Kiro, Copilot (CI-maintained)
- **dev/** — dev-only skills (repo-review, index-repo-docs)
- **docs/decisions/** — MADR-style architecture decision records with confidence scoring
- **flake.nix** — nixpkgs + nvfetcher + rust-overlay inputs, overlays, packages, devShell, lib, homeManagerModules
- **home-manager/** — home-manager module for declarative per-user installation
- **INSTALL.md** — installation and routing setup for all platforms and methods
- **references/** — canonical reference docs (symlinked into each skill's `references/`)
- **skills/** — SKILL.md files with per-skill `references/` subdirectories

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
