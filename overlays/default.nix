{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;

  # Wrapper: evaluate sources once per final pkgs, pass to all overlays.
  # Each overlay file has signature: sources: final: prev: { ... }
  withSources = overlayPaths: final: prev: let
    sources = import ./sources.nix {
      inherit (final) fetchurl fetchgit fetchFromGitHub dockerTools;
    };
    applyOverlay = path: (import path) sources final prev;
  in
    lib.foldl' lib.recursiveUpdate {} (map applyOverlay overlayPaths);

  localOverlays = [
    ./git-absorb.nix
    ./git-branchless.nix
    ./git-revise.nix
  ];
in
  lib.composeManyExtensions
  [inputs.rust-overlay.overlays.default (withSources localOverlays)]
