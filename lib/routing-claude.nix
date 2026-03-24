# Generate Claude Code routing table (Markdown for CLAUDE.md).
#
# Usage in home-manager or project config:
#   routing = inputs.stacked-workflow-skills.lib.mkClaudeRouting;
#
# Returns a string suitable for inclusion in a CLAUDE.md file.
let
  data = import ./routing-data.nix;

  header = ''
    ## Skill Routing — MANDATORY

    When the user is working with stacked commits, use the appropriate skill
    instead of running commands manually via Bash.

    <!-- dprint-ignore -->
    | Operation | Skill | Use INSTEAD of |
    |-----------|-------|----------------|'';

  mkRow = entry: "| ${entry.operation} | `${entry.skill}` | ${entry.insteadOf} |";

  rows = builtins.concatStringsSep "\n" (map mkRow data);

  footer = ''

    **RULE: Before running any git-branchless, git-absorb, or git-revise command
    via Bash, check if a skill covers the operation.** Skills include pre-flight
    checks, dry-run previews, conflict guidance, and post-operation verification
    that manual commands miss.'';
in
  header + "\n" + rows + "\n" + footer
