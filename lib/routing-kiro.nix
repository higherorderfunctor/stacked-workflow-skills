# Kiro steering file — reads pre-generated file.
#
# Usage:
#   routing = inputs.stacked-workflow-skills.lib.mkKiroSteering;
#
# Source of truth is .ruler/routing.md, generated via scripts/generate.sh.
builtins.readFile ../.generated/kiro-routing.md
