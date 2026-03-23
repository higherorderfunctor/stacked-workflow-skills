# stacked-workflow-skills

Skills and reference docs for stacked commit workflows with git-branchless,
git-absorb, and git-revise. Works with Claude Code, Kiro, GitHub Copilot, and
any tool that supports SKILL.md files.

## Prerequisites

### Manual

- [git-absorb](https://github.com/tummychow/git-absorb) — `cargo install
  --git https://github.com/tummychow/git-absorb`
- [git-branchless](https://github.com/arxanas/git-branchless) — `cargo install
  --git https://github.com/arxanas/git-branchless git-branchless`
- [git-revise](https://github.com/mystor/git-revise) (optional) — `pip install
  git-revise`

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

### Skills

<!-- dprint-ignore -->
| Skill | What it does |
|-------|-------------|
| `/stack-fix` | Absorb fixes into correct stack commits (auto via git-absorb, guided manual fallback for content moves) |
| `/stack-split` | Split a large commit into reviewable atomic commits |

### References

Distilled docs for each tool — command reference, recipes, anti-patterns,
integration notes:

- `references/philosophy.md` — atomic commit principles and ordering conventions
- `references/git-branchless.md` — smartlog, move, sync, submit, revsets
- `references/git-absorb.md` — automatic fixup routing
- `references/git-revise.md` — in-memory commit rewriting

Or use the combined overlay for all tools:

```nix
nixpkgs.overlays = [
  inputs.stacked-workflow-skills.overlays.default
];
```
