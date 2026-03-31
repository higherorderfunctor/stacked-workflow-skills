## Flake Structure

- **CONTRIBUTING.md** — development setup and workflow
- **dev/** — dev-only skills (repo-review, index-repo-docs)
- **docs/decisions/** — MADR-style architecture decision records with confidence scoring
- **flake.nix** — nixpkgs + nvfetcher + rust-overlay inputs, overlays, packages, devShells, lib, homeManagerModules
- **fragments/** — source markdown fragments for instruction generation
- **home-manager/** — home-manager module for declarative per-user installation
- **INSTALL.md** — installation and routing setup for all platforms and methods
- **references/** — canonical reference docs (symlinked into each skill's `references/`)
- **scripts/** — pre-commit hook
- **skills/** — SKILL.md files with per-skill `references/` subdirectories
