# CLAUDE.md

@AGENTS.md

Claude Code-specific routing and skill configuration. When instructions
conflict, this file takes precedence over `AGENTS.md`.

<!-- Generated from .ruler/ via scripts/generate.sh — edit .ruler/ sources instead -->

## Local Skill Priority

This repo's `.claude/skills/` contains `sws-*` prefixed skills that point to
the local working copies. When both a global skill (e.g., `/stack-fix`) and a
local variant (e.g., `/sws-stack-fix`) are available, **always use the `sws-*`
variant** so that edits to skills in this repo take effect immediately.

## agnix MCP Integration

When the `agnix` MCP server is available, use `validate_project` to validate
all agent configs after editing SKILL.md, CLAUDE.md, AGENTS.md, or MCP config
files. Use `get_rule_docs` to look up specific rule details when fixing
violations. The pre-commit hook is a safety net — prefer proactive validation.

**Known limitation:** agnix-mcp does not read `.agnix.toml` (uses default
config). Ignore diagnostics for rules suppressed in `.agnix.toml` — the
CLI and pre-commit hook apply suppressions correctly.

@.generated/claude-routing.md
