# stacked-workflow-skills

Skills and reference docs for stacked commit workflows with git-branchless,
git-absorb, and git-revise. Works with Claude Code, Kiro, GitHub Copilot, and
any tool that supports SKILL.md files.

## Prerequisites

- [Nix](https://nixos.org/) with flakes enabled (for devShell and formatter)
- Or manually install: [git-branchless](https://github.com/arxanas/git-branchless),
  [git-absorb](https://github.com/tummychow/git-absorb),
  [git-revise](https://github.com/mystor/git-revise)
- Optional: [direnv](https://direnv.net/) with
  [nix-direnv](https://github.com/nix-community/nix-direnv) to automatically
  load the flake dev shell (`.envrc` uses `use flake` which requires nix-direnv)
