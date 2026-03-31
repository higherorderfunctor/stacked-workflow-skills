# Fragment-based instruction generation.
#
# Single source of truth for which fragments compose each profile
# and how each ecosystem wraps the output (frontmatter, paths).
#
# Usage:
#   lib.mkInstructions { profile = "package"; ecosystem = "claude"; }
#   lib.mkInstructions { profile = "dev"; ecosystem = "kiro"; }
{lib}: let
  fragmentsDir = ../fragments;

  # -- Fragment registry ------------------------------------------------------

  # Read a fragment file by name (without .md extension)
  readFragment = name: builtins.readFile "${fragmentsDir}/${name}.md";

  # -- Profiles ---------------------------------------------------------------

  # Which fragments compose each profile, in order
  profiles = {
    # Consumer install — what users need to USE the skills
    package = [
      "routing-table"
    ];

    # In-repo development — what devs need to WORK ON this repo
    dev = [
      "project-overview"
      "commit-convention"
      "build-commands"
      "validation"
      "flake-structure"
      "coding-standards"
      "tooling-preference"
      "development"
      "continuous-improvement"
      "routing-table"
      "dev-skills"
      "operations"
    ];
  };

  # -- Ecosystems -------------------------------------------------------------

  # Per-ecosystem frontmatter configuration
  ecosystems = {
    claude = {
      frontmatter = null; # no frontmatter
    };
    kiro = {
      frontmatter = {
        name = "stacked-workflow";
        inclusion = "auto";
        description = "Skill routing for stacked commit workflows";
      };
    };
    copilot = {
      frontmatter = {
        applyTo = ''"**"'';
      };
    };
    # AGENTS.md — dev profile only, no frontmatter
    agentsmd = {
      frontmatter = null;
    };
  };

  # -- Builders ---------------------------------------------------------------

  # Concatenate fragments for a profile with blank line separators
  mkContent = profile:
    builtins.concatStringsSep "\n"
    (map readFragment profiles.${profile});

  # Build YAML frontmatter block from an attrset
  mkFrontmatter = attrs:
    "---\n"
    + builtins.concatStringsSep "\n"
    (lib.mapAttrsToList (k: v: "${k}: ${v}") attrs)
    + "\n---\n";

  # Build final output: optional frontmatter + concatenated fragments
  mkInstructions = {
    profile,
    ecosystem,
  }: let
    content = mkContent profile;
    fm = ecosystems.${ecosystem}.frontmatter;
  in
    if fm == null
    then content
    else mkFrontmatter fm + "\n" + content;
in {
  inherit
    ecosystems
    mkContent
    mkFrontmatter
    mkInstructions
    profiles
    readFragment
    ;
}
