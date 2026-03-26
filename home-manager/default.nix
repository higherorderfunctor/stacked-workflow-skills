# Home-manager module for stacked-workflow-skills.
#
# Convenience wrapper for global/per-user installation. Sets git config
# presets and wires AI tool integrations (Claude Code, Kiro, Copilot).
#
# Per-project/repo installation should use a devShell flake, manual
# symlinks, or agentic install — not this module.
#
# Usage:
#   imports = [ inputs.stacked-workflow-skills.homeManagerModules.default ];
#   stacked-workflows.enable = true;
{
  config,
  lib,
  options,
  ...
}: let
  cfg = config.stacked-workflows;

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

  claudeAvailable =
    (lib.hasAttrByPath ["programs" "claude-code" "enable"] options)
    && config.programs.claude-code.enable;
in {
  options.stacked-workflows = {
    enable = lib.mkEnableOption "stacked workflow skills and references";

    gitPreset = lib.mkOption {
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

    integrations = {
      claude = {
        enable = lib.mkEnableOption "Claude Code integration";
      };

      copilot = {
        enable = lib.mkEnableOption "GitHub Copilot CLI integration (gh copilot)";
      };

      kiro = {
        enable = lib.mkEnableOption "Kiro integration";
      };
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # ── Assertions ─────────────────────────────────────────────────────
    {
      assertions = [
        {
          assertion =
            !(cfg.gitPreset
              != "none"
              && (lib.attrByPath ["pull" "ff"] null
                config.programs.git.settings)
              != null);
          message = ''
            programs.git.settings.pull.ff conflicts with
            stacked-workflows.gitPreset.

            Since Git 2.34, pull.ff = "only" takes priority over
            pull.rebase = true, causing "git pull" to fail when local
            commits exist. Remove pull.ff from your git settings or set
            stacked-workflows.gitPreset = "none".
          '';
        }
        {
          assertion =
            !(cfg.integrations.claude.enable && !claudeAvailable);
          message = ''
            stacked-workflows.integrations.claude.enable requires
            programs.claude-code to be imported and enabled.

            Either enable programs.claude-code.enable = true or disable
            the integration: stacked-workflows.integrations.claude.enable = false;
          '';
        }
      ];
    }

    # ── Git configuration ──────────────────────────────────────────────
    (lib.mkIf (cfg.gitPreset != "none") {
      programs.git.settings = mkDefaultRecursive gitSettings.${cfg.gitPreset};
    })

    # ── Claude Code ────────────────────────────────────────────────────
    (lib.mkIf (cfg.integrations.claude.enable && claudeAvailable) {
      programs.claude-code = {
        # Per-skill entries merge with skills from other modules
        skills = {
          stack-fix = "${self.skillsDir}/stack-fix";
          stack-plan = "${self.skillsDir}/stack-plan";
          stack-split = "${self.skillsDir}/stack-split";
          stack-submit = "${self.skillsDir}/stack-submit";
          stack-summary = "${self.skillsDir}/stack-summary";
          stack-test = "${self.skillsDir}/stack-test";
        };
        memory.text = lib.mkAfter self.routingClaude;
      };
      # Per-file references so user's existing entries aren't clobbered
      home.file = {
        ".claude/references/git-absorb.md".source = "${self.referencesDir}/git-absorb.md";
        ".claude/references/git-branchless.md".source = "${self.referencesDir}/git-branchless.md";
        ".claude/references/git-revise.md".source = "${self.referencesDir}/git-revise.md";
        ".claude/references/philosophy.md".source = "${self.referencesDir}/philosophy.md";
        ".claude/references/recommended-config.md".source = "${self.referencesDir}/recommended-config.md";
      };
    })

    # ── Copilot CLI ────────────────────────────────────────────────────
    (lib.mkIf cfg.integrations.copilot.enable {
      home.file.".copilot/skills".source = self.skillsDir;
      home.file.".copilot/copilot-instructions.md".text = self.routingCopilot;
    })

    # ── Kiro ───────────────────────────────────────────────────────────
    (lib.mkIf cfg.integrations.kiro.enable {
      home.file.".kiro/skills".source = self.skillsDir;
      home.file.".kiro/steering/stacked-workflow.md".text = self.routingKiro;
    })
  ]);
}
