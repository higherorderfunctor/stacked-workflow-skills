_: final: _: let
  sources = import ./sources.nix {inherit (final) fetchurl fetchgit fetchFromGitHub dockerTools;};
  nv = sources.agnix;

  # agnix requires Rust edition 2024 (>= 1.91)
  rust = final.rust-bin.stable.latest.default;
  rustPlatform = final.makeRustPlatform {
    cargo = rust;
    rustc = rust;
  };
in {
  agnix = rustPlatform.buildRustPackage {
    pname = "agnix";
    inherit (nv) version src;
    cargoHash = nv.cargoHash;

    nativeBuildInputs = [final.pkg-config];
    buildInputs = final.lib.optionals final.stdenv.hostPlatform.isDarwin [
      final.darwin.apple_sdk.frameworks.Security
      final.darwin.apple_sdk.frameworks.SystemConfiguration
    ];

    # Build only the CLI crate
    cargoBuildFlags = ["-p" "agnix-cli"];
    cargoTestFlags = ["-p" "agnix-cli"];

    # Telemetry test fails in Nix sandbox (no $HOME / no network)
    checkFlags = ["--skip" "test_telemetry_enable_disable_roundtrip"];

    meta = {
      description = "Linter and LSP for AI coding assistant config files";
      homepage = "https://github.com/agent-sh/agnix";
      license = final.lib.licenses.mit;
      mainProgram = "agnix";
    };
  };
}
