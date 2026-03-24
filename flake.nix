{
  description = "Skills and references for stacked commit workflows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    inherit (nixpkgs) lib;
    import' = path: import path {};
    sources = import' ./overlays/sources.nix;
    perPkg = name:
      lib.composeManyExtensions [sources (import' ./overlays/${name}.nix)];
  in {
    lib = {
      gitConfig = import ./lib/git-config.nix;
      gitConfigFull = import ./lib/git-config-full.nix;
      mkClaudeRouting = import ./lib/routing-claude.nix;
      mkCopilotInstructions = import ./lib/routing-copilot.nix;
      mkKiroSteering = import ./lib/routing-kiro.nix;
      routing = import ./lib/routing-data.nix;
    };

    overlays = {
      default = import ./overlays {inherit inputs;};
      git-absorb = perPkg "git-absorb";
      git-branchless = perPkg "git-branchless";
      git-revise = perPkg "git-revise";
    };

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in {
      inherit (pkgs) git-absorb git-branchless git-revise;

      install = pkgs.writeShellApplication {
        name = "stacked-workflow-install";
        text = let
          skillsSrc = "${self}/skills";
          refsSrc = "${self}/references";
          claudeRouting = self.lib.mkClaudeRouting;
          kiroRouting = self.lib.mkKiroSteering;
          copilotRouting = self.lib.mkCopilotInstructions;
        in ''
          shopt -s inherit_errexit 2>/dev/null || :

          usage() {
            cat <<USAGE
          Usage: stacked-workflow-install [--global | --project | --routing-only | --help]

          Install stacked workflow skills and references.

          Options:
            --global        Install to ~/.claude/ (default)
            --project       Install to .claude/ in the current directory
            --routing-only  Print routing tables for all platforms to stdout
            --help          Show this help message
          USAGE
          }

          MODE="global"
          while [[ $# -gt 0 ]]; do
            case "$1" in
              --global) MODE="global"; shift ;;
              --project) MODE="project"; shift ;;
              --routing-only) MODE="routing-only"; shift ;;
              --help) usage; exit 0 ;;
              *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
            esac
          done

          case "$MODE" in
            global)
              dest="$HOME/.claude"
              mkdir -p "$dest/skills" "$dest/references"
              cp -r ${skillsSrc}/* "$dest/skills/"
              cp -r ${refsSrc}/* "$dest/references/"
              echo "Installed skills and references to $dest"
              echo ""
              echo "Add the routing table to your ~/.claude/CLAUDE.md:"
              echo "  stacked-workflow-install --routing-only"
              ;;
            project)
              dest=".claude"
              mkdir -p "$dest/skills" "$dest/references"
              cp -r ${skillsSrc}/* "$dest/skills/"
              cp -r ${refsSrc}/* "$dest/references/"
              echo "Installed skills and references to $dest/"
              echo ""
              echo "Add the routing table to your CLAUDE.md:"
              echo "  stacked-workflow-install --routing-only"
              ;;
            routing-only)
              echo "=== Claude Code (CLAUDE.md) ==="
              echo ""
              cat <<'CLAUDE_ROUTING'
          ${claudeRouting}
          CLAUDE_ROUTING
              echo ""
              echo "=== Kiro (.kiro/steering/*.md) ==="
              echo ""
              cat <<'KIRO_ROUTING'
          ${kiroRouting}
          KIRO_ROUTING
              echo ""
              echo "=== GitHub Copilot (.github/instructions/*.md) ==="
              echo ""
              cat <<'COPILOT_ROUTING'
          ${copilotRouting}
          COPILOT_ROUTING
              ;;
          esac
        '';
      };
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in {
      default = pkgs.mkShellNoCC {
        packages =
          builtins.attrValues self.packages.${system}
          ++ [
            # Formatting
            pkgs.alejandra
            pkgs.dprint

            # Spellcheck
            pkgs.cspell

            # Version tracking
            inputs.nvfetcher.packages.${system}.default
          ];
      };
    });

    checks = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      formatting =
        pkgs.runCommand "check-formatting" {
          nativeBuildInputs = [pkgs.alejandra];
        } ''
          alejandra --check --exclude ${self}/overlays/.nvfetcher ${self}
          touch $out
        '';

      spelling =
        pkgs.runCommand "check-spelling" {
          nativeBuildInputs = [pkgs.cspell pkgs.findutils];
        } ''
          cd ${self}
          find . -name '*.md' -not -path './overlays/.nvfetcher/*' \
            -exec cspell lint --no-progress --no-color --root ${self} {} +
          touch $out
        '';
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
