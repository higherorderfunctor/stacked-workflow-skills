_: _: prev: let
  nv = prev.nv-sources.git-branchless;
in {
  git-branchless = prev.git-branchless.overrideAttrs {
    inherit (nv) version src;
    cargoHash = nv.cargoHash;
  };
}
