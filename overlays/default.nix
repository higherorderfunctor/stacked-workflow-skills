{inputs, ...}: let
  inherit (inputs.nixpkgs) lib;
  import' = path: import path {};
  overlays = [
    ./sources.nix
  ];
in
  lib.composeManyExtensions (map import' overlays)
