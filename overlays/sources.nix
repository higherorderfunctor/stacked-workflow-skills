# Resolve nvfetcher sources with sidecar hashes.
# Each overlay calls: nv = (import ./sources.nix fetchArgs).git-branchless;
{
  fetchurl,
  fetchgit,
  fetchFromGitHub,
  dockerTools,
}: let
  generated = import ./.nvfetcher/generated.nix {
    inherit fetchurl fetchgit fetchFromGitHub dockerTools;
  };
  hashes = builtins.fromJSON (builtins.readFile ./hashes.json);
  merge = name: attrs:
    attrs // (hashes.${name} or {});
in
  builtins.mapAttrs merge generated
