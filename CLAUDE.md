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
