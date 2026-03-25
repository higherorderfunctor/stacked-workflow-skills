# Generate GitHub Copilot instructions for skill routing.
#
# Usage:
#   routing = inputs.stacked-workflow-skills.lib.mkCopilotInstructions;
#
# Returns a string suitable for a .github/instructions/*.md file.
let
  data = import ./routing-data.nix;

  frontmatter = ''
    ---
    applyTo: "**"
    ---'';

  header = ''

    # Stacked Workflow Skill Routing

    When working with stacked commits, invoke the appropriate skill instead of
    running git commands directly.

    | Operation | Skill | Use INSTEAD of |
    |-----------|-------|----------------|'';

  mkRow = entry: "| ${entry.operation} | `${entry.skill}` | ${entry.insteadOf} |";

  rows = builtins.concatStringsSep "\n" (map mkRow data);

  footer = ''

    **Always check if a skill covers the operation before running raw
    git-branchless, git-absorb, or git-revise commands.**'';
in
  frontmatter + "\n" + header + "\n" + rows + "\n" + footer
