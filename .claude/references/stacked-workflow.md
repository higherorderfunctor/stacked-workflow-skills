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

**Note:** `nix flake check` only includes tracked files — see
[Nix Workflow](#nix-workflow) below.

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

- **CONTRIBUTING.md** — development setup and workflow
- **dev/** — dev-only skills (repo-review, index-repo-docs)
- **docs/decisions/** — MADR-style architecture decision records with confidence scoring
- **flake.nix** — nixpkgs + nvfetcher + rust-overlay inputs, overlays, packages, devShells, lib, homeManagerModules
- **fragments/** — source markdown fragments for instruction generation
- **home-manager/** — home-manager module for declarative per-user installation
- **INSTALL.md** — installation and routing setup for all platforms and methods
- **references/** — canonical reference docs (symlinked into each skill's `references/`)
- **scripts/** — pre-commit hook
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

## External Tooling

When accessing external services, prefer the highest-fidelity integration
available:

1. **MCP server** — richest context, structured responses, stays in-conversation
2. **CLI tool** (e.g., `gh`, `curl`) — scriptable, good for batch operations
3. **Direct web access** — last resort, use only when MCP and CLI are unavailable

For GitHub specifically: prefer the `github-mcp` server over `gh` CLI over
raw API calls or web fetches.

## Development

See `CONTRIBUTING.md` for devShell setup, global package alternatives, and
the routing file generation pipeline.

### Tool Reference Maintenance

Reference docs for dev tools live in `references/`. When tools are upgraded
(via nvfetcher) or their configuration changes, update the corresponding
reference doc. Use `/index-repo-docs <tool>` to refresh from upstream, then
curate the output.

<!-- dprint-ignore -->
| Doc                          | Covers                                           |
| ---------------------------- | ------------------------------------------------ |
| `references/agnix.md`        | agnix CLI, `.agnix.toml` config, rule categories |
| `references/nix-workflow.md` | Nix conventions, devShell, packaging patterns    |

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

