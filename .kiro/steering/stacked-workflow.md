---
inclusion: auto
description: Skill routing for stacked commit workflows
---

# Stacked Workflow Skill Routing

When working with stacked commits, invoke the appropriate skill instead of
running git commands directly.

## Audit stack quality before restructure

**Skill:** `/stack-summary`
**Use instead of:** Manual `git log` inspection

## Commit uncommitted work as an atomic stack

**Skill:** `/stack-plan`
**Use instead of:** `git add -A && git commit` (single monolithic commit)

## Edit earlier commit (content moves, structural changes)

**Skill:** `/stack-fix`
**Use instead of:** Manual `git prev` + edit + `git amend` + `git restack --merge`

## Fix lines in earlier commit

**Skill:** `/stack-fix`
**Use instead of:** `git absorb`, `git commit --fixup`, manual checkout + amend

## Plan and build a commit stack from a description

**Skill:** `/stack-plan`
**Use instead of:** Ad-hoc `git record` / `git commit` without a plan

## Push stack for review

**Skill:** `/stack-submit`
**Use instead of:** Manual `git sync` + `git submit` + `gh pr create`

## Restructure/reorder existing commits

**Skill:** `/stack-plan`
**Use instead of:** `git rebase -i`, `git reset --soft`, `git move` sequences

## Split a large commit

**Skill:** `/stack-split`
**Use instead of:** `git rebase -i` + edit, `git reset HEAD^`

## Test across stack

**Skill:** `/stack-test`
**Use instead of:** Manual `git test run` or looping `git checkout` + test

---

**Always check if a skill covers the operation before running raw
git-branchless, git-absorb, or git-revise commands.**