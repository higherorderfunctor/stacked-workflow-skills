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
    overlays = {
      default = import ./overlays {inherit inputs;};
      git-absorb = perPkg "git-absorb";
      git-branchless = perPkg "git-branchless";
    };

    packages = forAllSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
    in {
      inherit (pkgs) git-absorb git-branchless;
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShellNoCC {
        packages = [
          # Formatting
          pkgs.alejandra
          pkgs.dprint

          # Stacked workflow tools
          pkgs.git-absorb
          pkgs.git-branchless
          pkgs.git-revise

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
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
  };
}
