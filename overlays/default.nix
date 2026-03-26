{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
  # Apply the unused first arg so local overlays can be composed
  import' = path: import path {};
  localOverlays = [
    ./agnix.nix
    ./git-absorb.nix
    ./git-branchless.nix
    ./git-revise.nix
  ];
in
  lib.composeManyExtensions
  ([inputs.rust-overlay.overlays.default] ++ map import' localOverlays)
