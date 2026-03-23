# stacked-workflow-skills

Skills and reference docs for stacked commit workflows with git-branchless,
git-absorb, and git-revise. Works with Claude Code, Kiro, GitHub Copilot, and
any tool that supports SKILL.md files.

## Prerequisites

### Manual

- [git-branchless](https://github.com/arxanas/git-branchless) — `cargo install
  --git https://github.com/arxanas/git-branchless git-branchless`

### Nix overlay

This flake provides an overlay with packages built from the latest release
sources (tracked via nvfetcher). Use per-package overlays for selective
installation:

```nix
{
  inputs.stacked-workflow-skills.url = "github:you/stacked-workflow-skills";
}

# In your configuration or home-manager:
nixpkgs.overlays = [
  inputs.stacked-workflow-skills.overlays.git-branchless
];
# Then use pkgs.git-branchless anywhere
```

Optional: [direnv](https://direnv.net/) with
[nix-direnv](https://github.com/nix-community/nix-direnv) to automatically
load the flake dev shell (`.envrc` uses `use flake` which requires nix-direnv).

Or use the combined overlay for all tools:

```nix
nixpkgs.overlays = [
  inputs.stacked-workflow-skills.overlays.default
];
```
