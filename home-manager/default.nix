# Home-manager module for stacked-workflow-skills.
#
# Integrates with programs.claude-code when available and enabled
# (home-manager >= 25.11), falls back to home.file otherwise.
#
# Usage:
#   imports = [ inputs.stacked-workflow-skills.homeManagerModules.default ];
#   services.stacked-workflow-skills.enable = true;
{
  config,
  lib,
  ...
}: let
  cfg = config.services.stacked-workflow-skills;
  self = import ./paths.nix;
  claudeEnabled =
    (lib.hasAttrByPath ["programs" "claude-code" "enable"] config)
    && config.programs.claude-code.enable;
in {
  options.services.stacked-workflow-skills = {
    enable = lib.mkEnableOption "stacked workflow skills and references";

    claudeCode = {
      enable =
        lib.mkEnableOption "Claude Code integration via programs.claude-code"
        // {default = cfg.enable && claudeEnabled;};

      routing = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Include the skill routing table in Claude Code memory.
          The routing table tells Claude when to invoke each skill.
        '';
      };
    };

    rawPaths = {
      enable =
        lib.mkEnableOption "raw path installation via home.file"
        // {default = cfg.enable && !cfg.claudeCode.enable;};
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Path A: programs.claude-code integration (home-manager >= 25.11)
    (lib.mkIf cfg.claudeCode.enable {
      programs.claude-code = {
        skillsDir = self.skillsDir;
        # References are loaded by skills on demand — install via home.file
      };
      home.file.".claude/references".source = self.referencesDir;
    })

    # Path A: optional routing in memory
    (lib.mkIf (cfg.claudeCode.enable && cfg.claudeCode.routing) {
      programs.claude-code.memory.text = lib.mkAfter (import ../lib/routing-claude.nix);
    })

    # Path B: raw paths (no programs.claude-code)
    (lib.mkIf cfg.rawPaths.enable {
      home.file = {
        ".claude/references".source = self.referencesDir;
        ".claude/skills".source = self.skillsDir;
      };
    })
  ]);
}
