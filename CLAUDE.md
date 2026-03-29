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

@.generated/claude-routing.md
