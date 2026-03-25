# Home-manager module for stacked-workflow-skills.
#
# Convenience wrapper for global/per-user installation. Sets git config,
# Claude Code integration, Kiro steering, and Copilot instructions.
#
# Per-project/repo installation should use a devShell flake, manual
# symlinks, or agentic install — not this module.
#
# Usage:
#   imports = [ inputs.stacked-workflow-skills.homeManagerModules.default ];
#   programs.stacked-workflow-skills.enable = true;
{
  config,
  lib,
  options,
  ...
}: let
  cfg = config.programs.stacked-workflow-skills;

  self = {
    skillsDir = ../skills;
    referencesDir = ../references;
    routingClaude = import ../lib/routing-claude.nix;
    routingCopilot = import ../lib/routing-copilot.nix;
    routingKiro = import ../lib/routing-kiro.nix;
    gitConfig = import ../lib/git-config.nix;
    gitConfigFull = import ../lib/git-config-full.nix;
  };

  # Apply mkDefault to every leaf value in a nested attrset so users can
  # override individual keys at normal priority.
  mkDefaultRecursive = lib.mapAttrsRecursive (_path: lib.mkDefault);

  gitSettings = {
    "full" = self.gitConfigFull;
    "minimal" = self.gitConfig;
    "none" = {};
  };

  claudeEnabled =
    (lib.hasAttrByPath ["programs" "claude-code" "enable"] options)
    && config.programs.claude-code.enable;
in {
  options.programs.stacked-workflow-skills = {
    enable = lib.mkEnableOption "stacked workflow skills and references";

    git = lib.mkOption {
      type = lib.types.enum ["full" "minimal" "none"];
      default = "none";
      description = ''
        Git configuration preset for stacked workflows.

        - `"minimal"` — required + strongly recommended settings
        - `"full"` — all recommended settings (branchless, revise, general git)
        - `"none"` — no git configuration changes

        All values are set at `mkDefault` priority so you can override
        individual keys at normal priority in `programs.git.settings`.
      '';
    };

    claude = {
      enable =
        lib.mkEnableOption "Claude Code integration"
        // {default = cfg.enable && claudeEnabled;};
    };

    copilot = {
      enable = lib.mkEnableOption "GitHub Copilot CLI integration (gh copilot)";
    };

    kiro = {
      enable = lib.mkEnableOption "Kiro integration";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # ── Git configuration ──────────────────────────────────────────────
    (lib.mkIf (cfg.git != "none") {
      programs.git.settings = mkDefaultRecursive gitSettings.${cfg.git};
    })

    # ── Claude Code ────────────────────────────────────────────────────
    (lib.mkIf (cfg.claude.enable && claudeEnabled) {
      programs.claude-code = {
        skillsDir = self.skillsDir;
      };
      programs.claude-code.memory.text = lib.mkAfter self.routingClaude;
      home.file.".claude/references".source = self.referencesDir;
    })

    # ── Copilot CLI (gh copilot / copilot CLI) ───────────────────────────
    (lib.mkIf cfg.copilot.enable {
      home.file.".copilot/skills".source = self.skillsDir;
      home.file.".copilot/copilot-instructions.md".text = self.routingCopilot;
    })

    # ── Kiro (global user config) ──────────────────────────────────────
    (lib.mkIf cfg.kiro.enable {
      home.file.".kiro/skills".source = self.skillsDir;
      home.file.".kiro/steering/stacked-workflow.md".text = self.routingKiro;
    })
  ]);
}
