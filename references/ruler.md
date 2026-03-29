# Ruler Quick Reference

Ruler distributes a single set of rules to all AI coding agent instruction
files. Source lives in `.ruler/`, output goes to per-agent paths.

> **Note:** This repo uses `scripts/generate.sh` instead of `ruler apply`
> because ruler cannot inject per-ecosystem YAML frontmatter or isolate
> from parent `AGENTS.md` files. This doc is a general reference for the
> ruler tool itself. See `CONTRIBUTING.md` for the actual generation
> workflow.

- **Repo**: github.com/intellectronica/ruler
- **Version in devShell**: tracking main branch

## CLI

```bash
ruler apply              # generate all agent instruction files
ruler apply --dry-run    # preview without writing
ruler apply --agents claude,kiro  # specific agents only
ruler apply --no-gitignore        # don't update .gitignore
ruler apply --nested     # enable nested rule loading (monorepo)
ruler apply --verbose    # show what's being written

ruler revert             # undo all apply changes (restores .bak files)
ruler init               # scaffold .ruler/ directory
```

## Source Directory (`.ruler/`)

```
.ruler/
├── dev-skills.md       # dev-only skills
├── operations.md       # operations without skills
└── routing.md          # routing table
```

**File precedence** (highest to lowest):

1. Root `AGENTS.md` (outside `.ruler/`)
2. `.ruler/AGENTS.md`
3. Legacy `instructions.md`
4. Other `.md` files (sorted alphabetically)

All files are concatenated with `<!-- Source: <path> -->` markers between
them. Every agent receives the **identical** concatenated content.

## Configuration (`ruler.toml`)

```toml
default_agents = ["claude", "kiro", "copilot"]

[agents.claude]
enabled = true
output_path = "CLAUDE.md"

[agents.kiro]
enabled = true
output_path = ".kiro/steering/ruler-output.md"

[agents.copilot]
enabled = true
output_path = ".github/instructions/stacked-workflow.instructions.md"

[gitignore]
enabled = false   # we commit generated files

[skills]
enabled = false   # we manage skills separately

[mcp]
enabled = false
```

### Per-agent options

- `enabled` (bool) — include this agent in `ruler apply`
- `output_path` (string) — where to write the instruction file
- `output_path_instructions` (string) — alternate instructions path
- `output_path_config` (string) — MCP config path

## Nested Mode (experimental)

```bash
ruler apply --nested
```

Or in `ruler.toml`:

```toml
nested = true
```

Recursively discovers `.ruler/` directories in subdirectories. Each
subdirectory's rules are concatenated into the parent's output. Useful
for monorepos.

## What Ruler Cannot Do

- **No per-agent body transformation** — all agents get identical content.
  If you need a table for Claude and sections for Kiro, you need post-
  processing.
- **No YAML frontmatter injection** — Kiro `inclusion:` / `name:` and
  Copilot `applyTo:` must be added outside ruler (see `scripts/generate.sh`).
- **No consumer vs in-repo variants** — single output per agent.
  `generate.sh` handles this by directly concatenating `.ruler/*.md`
  source files and writing per-ecosystem output with different YAML
  frontmatter via `printf`.

## Supported Agents

Claude Code, Kiro, Copilot, Cursor, Aider, Codex, Gemini CLI, Windsurf,
RooCode, Zed, and 20+ more. Full list in ruler README.
