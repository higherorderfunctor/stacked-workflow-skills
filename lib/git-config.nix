# Recommended git configuration for stacked commit workflows.
#
# Usage in home-manager:
#   programs.git.extraConfig = inputs.stacked-workflow-skills.lib.gitConfig;
#
# See references/recommended-config.md for explanations of each setting.
{
  # ── Required ──────────────────────────────────────────────────────

  branchless.core.mainBranch = "main";

  init.defaultBranch = "main";

  # ── Strongly Recommended ──────────────────────────────────────────

  absorb = {
    fixupTargetAlwaysSHA = true;
    maxStack = 50;
    oneFixupPerCommit = true;
  };

  merge.conflictStyle = "zdiff3";

  pull = {
    ff = "only";
    rebase = true;
  };

  rebase = {
    autoSquash = true;
    autoStash = true;
    updateRefs = true;
  };

  rerere = {
    autoupdate = true;
    enabled = true;
  };
}
