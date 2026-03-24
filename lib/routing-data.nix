# Canonical routing table for stacked workflow skills.
#
# Single source of truth for skill routing — consumed by per-platform
# generators (routing-claude.nix, routing-kiro.nix, routing-copilot.nix)
# and the install script.
#
# Usage:
#   nix eval .#lib.routing
#
# Each entry maps an operation to the skill that handles it, plus the
# commands the skill replaces.
[
  {
    operation = "Audit stack quality before restructure";
    skill = "/stack-summary";
    insteadOf = "Manual `git log` inspection";
  }
  {
    operation = "Commit uncommitted work as an atomic stack";
    skill = "/stack-plan";
    insteadOf = "`git add -A && git commit` (single monolithic commit)";
  }
  {
    operation = "Edit earlier commit (content moves, structural changes)";
    skill = "/stack-fix";
    insteadOf = "Manual `git prev` + edit + `git amend` + `git restack --merge`";
  }
  {
    operation = "Fix lines in earlier commit";
    skill = "/stack-fix";
    insteadOf = "`git absorb`, `git commit --fixup`, manual checkout + amend";
  }
  {
    operation = "Plan and build a commit stack from a description";
    skill = "/stack-plan";
    insteadOf = "Ad-hoc `git record` / `git commit` without a plan";
  }
  {
    operation = "Push stack for review";
    skill = "/stack-submit";
    insteadOf = "Manual `git sync` + `git submit` + `gh pr create`";
  }
  {
    operation = "Restructure/reorder existing commits";
    skill = "/stack-plan";
    insteadOf = "`git rebase -i`, `git reset --soft`, `git move` sequences";
  }
  {
    operation = "Split a large commit";
    skill = "/stack-split";
    insteadOf = "`git rebase -i` + edit, `git reset HEAD^`";
  }
  {
    operation = "Test across stack";
    skill = "/stack-test";
    insteadOf = "Manual `git test run` or looping `git checkout` + test";
  }
]
