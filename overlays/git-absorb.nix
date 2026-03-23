_: _: prev: let
  nv = prev.nv-sources.git-absorb;
in {
  git-absorb = prev.git-absorb.overrideAttrs {
    inherit (nv) version src;
    cargoHash = nv.cargoHash;
  };
}
