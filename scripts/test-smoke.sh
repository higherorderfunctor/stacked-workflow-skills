#!/usr/bin/env bash
set -euETo pipefail
shopt -s inherit_errexit 2>/dev/null || :

# Smoke test skill discovery across Claude Code, Kiro CLI, and Copilot CLI.
# Sends a prompt to each tool in non-interactive mode and checks that stack
# skills are mentioned in the response.
#
# Prerequisites: claude, kiro-cli, and/or gh copilot on $PATH.
# Skips tools that are not available.
#
# Usage: scripts/test-smoke.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROMPT="List all /slash commands you have available that contain 'stack' in the name. Just list the command names, one per line."
EXPECTED_SKILLS=("/stack-fix" "/stack-plan" "/stack-split" "/stack-submit" "/stack-summary" "/stack-test")

failures=0
tested=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; failures=$((failures + 1)); }
skip() { printf '  \033[33m⊘\033[0m %s\n' "$1"; }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

check_skills() {
  local tool="$1" output="$2"
  local found=0 missing=0

  for skill in "${EXPECTED_SKILLS[@]}"; do
    if grep -qiF "${skill}" <<< "${output}"; then
      found=$((found + 1))
    else
      fail "${tool}: missing ${skill} in response"
      missing=$((missing + 1))
    fi
  done

  if [[ ${missing} -eq 0 ]]; then
    pass "${tool}: all ${found} stack skills discovered"
  fi
}

# -- Claude Code -------------------------------------------------------------

section "Claude Code"

if command -v claude &>/dev/null; then
  tested=$((tested + 1))
  stderr_file=$(mktemp)
  output=$(cd "${REPO_ROOT}" && claude -p "${PROMPT}" 2>"${stderr_file}") || {
    fail "claude -p exited with error (stderr: $(cat "${stderr_file}"))"
    output=""
  }
  rm -f "${stderr_file}"

  if [[ -z "${output}" ]]; then
    fail "claude: empty response"
  else
    check_skills "claude" "${output}"
  fi
else
  skip "claude not found on PATH"
fi

# -- Kiro CLI ----------------------------------------------------------------

section "Kiro CLI"

if command -v kiro-cli &>/dev/null; then
  tested=$((tested + 1))
  stderr_file=$(mktemp)
  output=$(cd "${REPO_ROOT}" && kiro-cli chat --no-interactive "${PROMPT}" 2>"${stderr_file}") || {
    fail "kiro-cli exited with error (stderr: $(cat "${stderr_file}"))"
    output=""
  }
  rm -f "${stderr_file}"

  if [[ -z "${output}" ]]; then
    fail "kiro-cli: empty response"
  else
    check_skills "kiro-cli" "${output}"
  fi
else
  skip "kiro-cli not found on PATH"
fi

# -- Copilot CLI -------------------------------------------------------------

section "Copilot CLI"

if command -v gh &>/dev/null && gh copilot --help &>/dev/null 2>&1; then
  tested=$((tested + 1))
  stderr_file=$(mktemp)
  output=$(cd "${REPO_ROOT}" && gh copilot -- -p "${PROMPT}" -s 2>"${stderr_file}") || {
    fail "gh copilot exited with error (stderr: $(cat "${stderr_file}"))"
    output=""
  }
  rm -f "${stderr_file}"

  if [[ -z "${output}" ]]; then
    fail "gh-copilot: empty response"
  else
    check_skills "gh-copilot" "${output}"
  fi
else
  skip "gh copilot not found on PATH"
fi

# -- Summary -----------------------------------------------------------------

printf '\n'
if [[ ${tested} -eq 0 ]]; then
  printf '\033[33mNo AI tools found on PATH — nothing tested.\033[0m\n'
  exit 2
elif [[ ${failures} -eq 0 ]]; then
  printf '\033[32mAll smoke tests passed (%d tool(s) tested).\033[0m\n' "${tested}"
else
  printf '\033[31m%d check(s) failed across %d tool(s).\033[0m\n' "${failures}" "${tested}"
  exit 1
fi
