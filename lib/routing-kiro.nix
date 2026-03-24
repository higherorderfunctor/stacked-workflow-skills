# Generate Kiro steering file for skill routing.
#
# Usage:
#   routing = inputs.stacked-workflow-skills.lib.mkKiroSteering;
#
# Returns a string suitable for a .kiro/steering/*.md file.
let
  data = import ./routing-data.nix;

  frontmatter = ''
    ---
    inclusion: manual
    description: Skill routing for stacked commit workflows
    ---'';

  intro = ''

    # Stacked Workflow Skill Routing

    When working with stacked commits, invoke the appropriate skill instead of
    running git commands directly.'';

  mkEntry = entry: ''

    ## ${entry.operation}

    **Skill:** `${entry.skill}`
    **Use instead of:** ${entry.insteadOf}'';

  entries = builtins.concatStringsSep "\n" (map mkEntry data);

  footer = ''

    ---

    **Always check if a skill covers the operation before running raw
    git-branchless, git-absorb, or git-revise commands.**'';
in
  frontmatter + "\n" + intro + "\n" + entries + "\n" + footer
