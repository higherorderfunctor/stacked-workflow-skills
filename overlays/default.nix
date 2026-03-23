{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
  import' = path: import path {};
  overlays = [
    ./sources.nix
    ./git-absorb.nix
    ./git-branchless.nix
  ];
in
  lib.composeManyExtensions (map import' overlays)
