# Claude Code routing table — reads pre-generated file.
#
# Usage:
#   routing = inputs.stacked-workflow-skills.lib.mkClaudeRouting;
#
# Source of truth is .ruler/routing.md, generated via scripts/generate.sh.
builtins.readFile ../.generated/claude-routing.md
