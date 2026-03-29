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
dprint fmt           # Format all files (markdown, JSON, Nix via alejandra)
nix flake check      # Validate flake, formatting, spelling, and agent configs
agnix --strict .     # Lint AI agent config files
```

**Note:** `nix flake check` only includes tracked files; add new files with
`git add` before running it in a dirty git tree.

### Formatting

After editing any file — regardless of how it was modified (Edit, Write,
Bash, sed, etc.) — run `dprint fmt <file>` on the changed file. dprint
handles markdown, JSON, and Nix (via alejandra). The PostToolUse hook
auto-formats after Edit/Write, but Bash edits bypass hooks. Always format
explicitly after Bash-based file modifications.

### Validation

After creating or modifying any SKILL.md, AGENTS.md, CLAUDE.md, `.mcp.json`,
or `.agnix.toml`, validate with agnix before committing. The pre-commit hook
runs `agnix --strict .` automatically on staged config files, but proactive
validation catches issues earlier.

Do not install packages globally — use tools available in the devShell. If
something is missing, ask the user or use `npx`/`uvx`/`nix run` instead.

If the Skill tool invocation fails (e.g., due to `disable-model-invocation`
or platform limitations), read the SKILL.md file directly and execute its
instructions step by step. The routing table is MANDATORY — skills must be
used even when the tool mechanism is unavailable.

## Flake Structure

- **.generated/** — pre-generated routing files for Claude, Kiro, Copilot
- **.ruler/** — source of truth for routing rules (modular markdown files)
- **CONTRIBUTING.md** — development setup and workflow
- **dev/** — dev-only skills (repo-review, index-repo-docs)
- **docs/decisions/** — MADR-style architecture decision records with confidence scoring
- **flake.nix** — nixpkgs + nvfetcher + rust-overlay inputs, overlays, packages, devShell, lib, homeManagerModules
- **home-manager/** — home-manager module for declarative per-user installation
- **INSTALL.md** — installation and routing setup for all platforms and methods
- **references/** — canonical reference docs (symlinked into each skill's `references/`)
- **scripts/** — `generate.sh` produces routing files from `.ruler/` source
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

## Development

See `CONTRIBUTING.md` for devShell setup, global package alternatives, and
the routing file generation pipeline.

### Tool Reference Maintenance

Reference docs for dev tools live in `references/`. When tools are upgraded
(via nvfetcher) or their configuration changes, update the corresponding
reference doc. Use `/index-repo-docs <tool>` to refresh from upstream, then
curate the output.

| Doc                          | Covers                                           |
| ---------------------------- | ------------------------------------------------ |
| `references/agnix.md`        | agnix CLI, `.agnix.toml` config, rule categories |
| `references/nix-workflow.md` | Nix conventions, devShell, packaging patterns    |
| `references/ruler.md`        | Ruler CLI, `.ruler/` source format, profiles     |

### Nix Workflow

Nix flakes only see tracked files. Always `git add` new files before running
`nix build`, `nix develop`, `nix flake check`, or `nix eval`. See
`references/nix-workflow.md` for full conventions.

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
