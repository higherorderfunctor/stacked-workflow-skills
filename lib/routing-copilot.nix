# Copilot instructions — reads pre-generated file.
#
# Usage:
#   routing = inputs.stacked-workflow-skills.lib.mkCopilotInstructions;
#
# Source of truth is .ruler/routing.md, generated via scripts/generate.sh.
builtins.readFile ../.generated/copilot-routing.md
