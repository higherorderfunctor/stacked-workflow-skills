#!/usr/bin/env bash
set -euETo pipefail
shopt -s inherit_errexit 2>/dev/null || :

# Structural validation for skill discovery across Claude Code, Kiro, and
# Copilot. Tests that files exist, symlinks resolve, frontmatter is correct,
# and generated files are fresh. No AI tools required.
#
# Usage: scripts/test-structural.sh

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
failures=0

pass() { printf '  \033[32m✓\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; failures=$((failures + 1)); }
section() { printf '\n\033[1m%s\033[0m\n' "$1"; }

# -- Skills exist and have valid SKILL.md ------------------------------------

section "Skills"

for skill in stack-fix stack-plan stack-split stack-submit stack-summary stack-test; do
  skill_dir="${REPO_ROOT}/skills/${skill}"
  skill_file="${skill_dir}/SKILL.md"

  if [[ -f "${skill_file}" ]]; then
    pass "skills/${skill}/SKILL.md exists"
  else
    fail "skills/${skill}/SKILL.md missing"
    continue
  fi

  # Frontmatter name matches directory
  name=$(sed -n 's/^name: *//p' "${skill_file}" | head -1)
  if [[ "${name}" == "${skill}" ]]; then
    pass "skills/${skill} name field matches directory"
  else
    fail "skills/${skill} name field '${name}' does not match directory '${skill}'"
  fi

  # References symlinks resolve
  if [[ -d "${skill_dir}/references" ]]; then
    broken=0
    for ref in "${skill_dir}"/references/*.md; do
      [[ -e "${ref}" ]] || { broken=1; fail "skills/${skill}/references/$(basename "${ref}") is a broken symlink"; }
    done
    [[ ${broken} -eq 0 ]] && pass "skills/${skill}/references/ symlinks resolve"
  fi
done

# -- Dev skills --------------------------------------------------------------

section "Dev skills"

for skill in index-repo-docs repo-review; do
  if [[ -f "${REPO_ROOT}/dev/${skill}/SKILL.md" ]]; then
    pass "dev/${skill}/SKILL.md exists"
  else
    fail "dev/${skill}/SKILL.md missing"
  fi
done

# -- Claude Code (.claude/) --------------------------------------------------

section "Claude Code"

for skill in sws-stack-fix sws-stack-plan sws-stack-split sws-stack-submit sws-stack-summary sws-stack-test sws-index-repo-docs sws-repo-review; do
  link="${REPO_ROOT}/.claude/skills/${skill}"
  if [[ -L "${link}" && -e "${link}" ]]; then
    pass ".claude/skills/${skill} symlink resolves"
  elif [[ -L "${link}" ]]; then
    fail ".claude/skills/${skill} symlink is broken"
  else
    fail ".claude/skills/${skill} missing"
  fi
done

if [[ -f "${REPO_ROOT}/CLAUDE.md" ]]; then
  pass "CLAUDE.md exists"
else
  fail "CLAUDE.md missing"
fi

# -- Kiro (.kiro/) -----------------------------------------------------------

section "Kiro"

for skill in stack-fix stack-plan stack-split stack-submit stack-summary stack-test index-repo-docs repo-review; do
  link="${REPO_ROOT}/.kiro/skills/${skill}"
  if [[ -L "${link}" && -e "${link}" ]]; then
    pass ".kiro/skills/${skill} symlink resolves"
  elif [[ -L "${link}" ]]; then
    fail ".kiro/skills/${skill} symlink is broken"
  else
    fail ".kiro/skills/${skill} missing"
  fi
done

steering="${REPO_ROOT}/.kiro/steering/stacked-workflow.md"
if [[ -f "${steering}" ]]; then
  pass ".kiro/steering/stacked-workflow.md exists"
  if grep -q '^inclusion: auto' "${steering}"; then
    pass "Kiro steering has inclusion: auto"
  else
    fail "Kiro steering missing inclusion: auto"
  fi
  if grep -q '^name: stacked-workflow' "${steering}"; then
    pass "Kiro steering has name: stacked-workflow"
  else
    fail "Kiro steering missing name: stacked-workflow"
  fi
else
  fail ".kiro/steering/stacked-workflow.md missing"
fi

# -- Copilot (.github/) ------------------------------------------------------

section "Copilot"

for skill in stack-fix stack-plan stack-split stack-submit stack-summary stack-test index-repo-docs repo-review; do
  link="${REPO_ROOT}/.github/skills/${skill}"
  if [[ -L "${link}" && -e "${link}" ]]; then
    pass ".github/skills/${skill} symlink resolves"
  elif [[ -L "${link}" ]]; then
    fail ".github/skills/${skill} symlink is broken"
  else
    fail ".github/skills/${skill} missing"
  fi
done

instructions="${REPO_ROOT}/.github/instructions/stacked-workflow.instructions.md"
if [[ -f "${instructions}" ]]; then
  pass ".github/instructions/stacked-workflow.instructions.md exists"
  if grep -q 'applyTo: "\*\*"' "${instructions}"; then
    pass "Copilot instructions has applyTo: \"**\""
  else
    fail "Copilot instructions missing applyTo: \"**\""
  fi
else
  fail ".github/instructions/stacked-workflow.instructions.md missing"
fi

# -- Generated files (.generated/) -------------------------------------------

section "Generated files"

for f in claude-routing.md kiro-routing.md copilot-routing.md; do
  gen="${REPO_ROOT}/.generated/${f}"
  if [[ -f "${gen}" ]]; then
    pass ".generated/${f} exists"
  else
    fail ".generated/${f} missing"
  fi
done

# Freshness: verify .generated/claude-routing.md contains .ruler/routing.md content
if grep -qF "Skill Routing" "${REPO_ROOT}/.generated/claude-routing.md" \
  && grep -qF "/stack-fix" "${REPO_ROOT}/.generated/claude-routing.md"; then
  pass "Generated files contain routing table content"
else
  fail "Generated files may be stale — run scripts/generate.sh"
fi

# Freshness: dev profile includes all .ruler/ sections
steering="${REPO_ROOT}/.kiro/steering/stacked-workflow.md"
if grep -qF "Dev-Only Skills" "${steering}" \
  && grep -qF "Operations Without Skills" "${steering}" \
  && grep -qF "Skill Routing" "${steering}"; then
  pass "Kiro dev profile includes all .ruler/ sections"
else
  fail "Kiro steering missing .ruler/ sections — run scripts/generate.sh"
fi

# -- Routing table content ---------------------------------------------------

section "Routing table content"

routing="${REPO_ROOT}/.ruler/routing.md"
if [[ -f "${routing}" ]]; then
  pass ".ruler/routing.md exists"
  for skill in /stack-fix /stack-plan /stack-split /stack-submit /stack-summary /stack-test; do
    if grep -qF "${skill}" "${routing}"; then
      pass "Routing table references ${skill}"
    else
      fail "Routing table missing ${skill}"
    fi
  done
else
  fail ".ruler/routing.md missing"
fi

# -- AGENTS.md ---------------------------------------------------------------

section "AGENTS.md"

if [[ -f "${REPO_ROOT}/AGENTS.md" ]]; then
  pass "AGENTS.md exists"
else
  fail "AGENTS.md missing"
fi

# -- Summary -----------------------------------------------------------------

printf '\n'
if [[ ${failures} -eq 0 ]]; then
  printf '\033[32mAll checks passed.\033[0m\n'
else
  printf '\033[31m%d check(s) failed.\033[0m\n' "${failures}"
  exit 1
fi
