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
    lib = {
      gitConfig = import ./lib/git-config.nix;
      gitConfigFull = import ./lib/git-config-full.nix;
      mkClaudeRouting = import ./lib/routing-claude.nix;
      mkCopilotInstructions = import ./lib/routing-copilot.nix;
      mkKiroSteering = import ./lib/routing-kiro.nix;
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
        overlays = [self.overlays.default (import' ./overlays/agnix.nix) (import' ./overlays/ruler.nix)];
      };
    in {
      default = pkgs.mkShellNoCC {
        packages =
          builtins.attrValues self.packages.${system}
          ++ [
            # Agent config linting and routing
            pkgs.agnix
            pkgs.ruler

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

      structural =
        pkgs.runCommand "check-structural" {
          nativeBuildInputs = [pkgs.bash pkgs.diffutils pkgs.gnugrep pkgs.gnused pkgs.coreutils];
        } ''
          bash ${self}/scripts/test-structural.sh
          touch $out
        '';
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
