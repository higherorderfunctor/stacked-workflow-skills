_: final: _: let
  sources = import ./sources.nix {inherit (final) fetchurl fetchgit fetchFromGitHub dockerTools;};
  nv = sources.ruler;
in {
  ruler = final.buildNpmPackage {
    pname = "ruler";
    inherit (nv) version src;
    npmDepsHash = nv.npmDepsHash;

    npmBuildScript = "build";

    installPhase = ''
      mkdir -p $out/lib/ruler $out/bin
      cp -r dist node_modules package.json $out/lib/ruler/
      makeWrapper ${final.nodejs}/bin/node $out/bin/ruler \
        --add-flags "$out/lib/ruler/dist/cli/index.js"
    '';

    nativeBuildInputs = [final.makeWrapper];

    meta = {
      description = "Apply the same rules to all coding agents";
      homepage = "https://github.com/intellectronica/ruler";
      license = final.lib.licenses.mit;
      mainProgram = "ruler";
    };
  };
}
