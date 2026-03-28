#!/usr/bin/env bash
set -euETo pipefail
shopt -s inherit_errexit 2>/dev/null || :

# Generate routing files from .ruler/ source for all ecosystems.
#
# Source files in .ruler/ are concatenated per profile:
#   package — routing.md only (for consumer installation)
#   dev     — all .ruler/*.md files (for working on this repo)
#
# Produces:
#   Published files (.generated/):
#     claude-routing.md            (no frontmatter)
#     kiro-routing.md              (inclusion: manual)
#     copilot-routing.md           (applyTo: "**")
#   In-repo files:
#     .kiro/steering/stacked-workflow.md      (inclusion: auto)
#     .github/instructions/stacked-workflow.instructions.md (applyTo: "**")
#
# Usage: scripts/generate.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RULER_DIR="${REPO_ROOT}/.ruler"

# -- Package profile (routing only) -----------------------------------------

PACKAGE_BODY="$(cat "${RULER_DIR}/routing.md")"

mkdir -p "${REPO_ROOT}/.generated"

# Claude: no frontmatter
printf '%s\n' "${PACKAGE_BODY}" > "${REPO_ROOT}/.generated/claude-routing.md"

# Kiro consumer: inclusion: manual
{
  printf '%s\n' '---'
  printf '%s\n' 'inclusion: manual'
  printf '%s\n' 'description: Skill routing for stacked commit workflows'
  printf '%s\n' '---'
  printf '\n%s\n' "${PACKAGE_BODY}"
} > "${REPO_ROOT}/.generated/kiro-routing.md"

# Copilot consumer: applyTo
{
  printf '%s\n' '---'
  printf '%s\n' 'applyTo: "**"'
  printf '%s\n' '---'
  printf '\n%s\n' "${PACKAGE_BODY}"
} > "${REPO_ROOT}/.generated/copilot-routing.md"

# -- Dev profile (full dev guidance) ----------------------------------------

# Concatenate all .ruler/*.md files (sorted, excludes ruler.toml)
DEV_BODY="$(cat "${RULER_DIR}"/dev-skills.md "${RULER_DIR}"/operations.md "${RULER_DIR}"/routing.md)"

# Kiro in-repo: inclusion: auto + name
mkdir -p "${REPO_ROOT}/.kiro/steering"
{
  printf '%s\n' '---'
  printf '%s\n' 'name: stacked-workflow'
  printf '%s\n' 'inclusion: auto'
  printf '%s\n' 'description: Skill routing for stacked commit workflows'
  printf '%s\n' '---'
  printf '\n%s\n' "${DEV_BODY}"
} > "${REPO_ROOT}/.kiro/steering/stacked-workflow.md"

# Copilot in-repo: applyTo
mkdir -p "${REPO_ROOT}/.github/instructions"
{
  printf '%s\n' '---'
  printf '%s\n' 'applyTo: "**"'
  printf '%s\n' '---'
  printf '\n%s\n' "${DEV_BODY}"
} > "${REPO_ROOT}/.github/instructions/stacked-workflow.instructions.md"

echo "Generated routing files from .ruler/ source."
