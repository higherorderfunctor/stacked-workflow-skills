{
  description = "Skills and references for stacked commit workflows";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nvfetcher = {
      url = "github:berberman/nvfetcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
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
    rustOverlay = inputs.rust-overlay.overlays.default;
    perPkg = name:
      lib.composeManyExtensions [rustOverlay (import' ./overlays/${name}.nix)];
  in {
    lib = let
      fragments = import ./lib/fragments.nix {inherit lib;};
    in {
      inherit fragments;
      gitConfig = import ./lib/git-config.nix;
      gitConfigFull = import ./lib/git-config-full.nix;
      # Legacy exports — now backed by fragments
      mkClaudeRouting = fragments.mkInstructions {
        profile = "package";
        ecosystem = "claude";
      };
      mkCopilotInstructions = fragments.mkInstructions {
        profile = "package";
        ecosystem = "copilot";
      };
      mkKiroSteering = fragments.mkInstructions {
        profile = "package";
        ecosystem = "kiro";
      };
    };

    homeManagerModules.default = import ./home-manager;

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
    });

    devShells = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        # default overlay for consumer packages + agnix (dev-only, not in default overlay)
        overlays = [self.overlays.default (import' ./overlays/agnix.nix)];
      };
    in {
      default = pkgs.mkShellNoCC {
        packages =
          builtins.attrValues self.packages.${system}
          ++ [
            # Agent config linting
            pkgs.agnix

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
      pkgsWithAgnix = import nixpkgs {
        inherit system;
        overlays = [rustOverlay (import' ./overlays/agnix.nix)];
      };
    in {
      agent-configs =
        pkgs.runCommand "check-agent-configs" {
          nativeBuildInputs = [pkgsWithAgnix.agnix];
        } ''
          cd ${self}
          agnix --strict .
          touch $out
        '';

      formatting =
        pkgs.runCommand "check-formatting" {
          nativeBuildInputs = [pkgs.dprint pkgs.alejandra];
        } ''
          cd ${self}
          dprint check
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

      structural =
        pkgs.runCommand "check-structural" {
          nativeBuildInputs = [pkgs.bash pkgs.gnugrep pkgs.gnused pkgs.coreutils];
        } ''
          bash ${self}/scripts/test-structural.sh
          touch $out
        '';
    });

    apps = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      fragments = import ./lib/fragments.nix {inherit lib;};

      generateScript = pkgs.writeShellApplication {
        name = "generate";
        text = let
          # Dev profile outputs
          claudeDev = fragments.mkInstructions {
            profile = "dev";
            ecosystem = "claude";
          };
          kiroDev = fragments.mkInstructions {
            profile = "dev";
            ecosystem = "kiro";
          };
          copilotDev = fragments.mkInstructions {
            profile = "dev";
            ecosystem = "copilot";
          };
          agentsmDev = fragments.mkInstructions {
            profile = "dev";
            ecosystem = "agentsmd";
          };
        in ''
          REPO_ROOT="$(pwd)"

          # Dev profile outputs — written directly to ecosystem paths
          mkdir -p "$REPO_ROOT/.claude/references"
          cat > "$REPO_ROOT/.claude/references/stacked-workflow.md" << 'FRAGMENT_EOF'
          ${claudeDev}
          FRAGMENT_EOF

          mkdir -p "$REPO_ROOT/.kiro/steering"
          cat > "$REPO_ROOT/.kiro/steering/stacked-workflow.md" << 'FRAGMENT_EOF'
          ${kiroDev}
          FRAGMENT_EOF

          mkdir -p "$REPO_ROOT/.github/instructions"
          cat > "$REPO_ROOT/.github/instructions/stacked-workflow.instructions.md" << 'FRAGMENT_EOF'
          ${copilotDev}
          FRAGMENT_EOF

          cat > "$REPO_ROOT/AGENTS.md" << 'FRAGMENT_EOF'
          # AGENTS.md

          Project instructions for AI coding assistants working in this repository.
          Read by Claude Code, Kiro, GitHub Copilot, Codex, and other tools that
          support the [AGENTS.md standard](https://agents.md).

          ${agentsmDev}
          FRAGMENT_EOF

          echo "Generated instruction files from fragments."
        '';
      };
    in {
      generate = {
        type = "app";
        program = "${generateScript}/bin/generate";
      };
    });

    formatter = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
      pkgs.writeShellApplication {
        name = "fmt";
        runtimeInputs = [pkgs.dprint pkgs.alejandra];
        text = ''
          dprint fmt "$@"
        '';
      });
  };
}
