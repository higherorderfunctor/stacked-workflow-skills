# stacked-workflow-skills

Skills and reference docs for stacked commit workflows with git-branchless,
git-absorb, and git-revise. Works with Claude Code, Kiro, GitHub Copilot, and
any tool that supports SKILL.md files.

## What's Included

### Skills

<!-- dprint-ignore -->
| Skill | What it does |
|-------|-------------|
| `/stack-fix` | Absorb fixes into correct stack commits (auto via git-absorb, guided manual fallback for content moves) |
| `/stack-plan` | Plan and build a commit stack from a description, uncommitted work, or existing commits |
| `/stack-split` | Split a large commit into reviewable atomic commits |
| `/stack-submit` | Sync, validate, push stack, and create stacked PRs |
| `/stack-summary` | Analyze stack quality, flag violations, produce planner-ready summary |
| `/stack-test` | Run tests or formatters across every commit in a stack |

### References

Each skill bundles the reference docs it needs in a `references/` subdirectory
(symlinked to the canonical top-level files). Skills load these automatically
during pre-flight — no separate reference installation needed.

Canonical reference docs in `references/`:

- `philosophy.md` — atomic commit principles and ordering conventions
- `git-branchless.md` — smartlog, move, sync, submit, revsets
- `git-absorb.md` — automatic fixup routing
- `git-revise.md` — in-memory commit rewriting
- `recommended-config.md` — git settings for stacked workflows

## Prerequisites

- [git-branchless](https://github.com/arxanas/git-branchless)
- [git-absorb](https://github.com/tummychow/git-absorb)
- [git-revise](https://github.com/mystor/git-revise) (optional, used by some
  recipes)

Install using your preferred method. This flake also provides an overlay
with packages built from latest release sources — see
[INSTALL.md](INSTALL.md) for Nix overlay details.

## Installation

### Quick Start

#### Claude Code

```bash
git clone https://github.com/higherorderfunctor/stacked-workflow-skills.git
mkdir -p ~/.claude/skills ~/.claude/references
ln -sfn /path/to/stacked-workflow-skills/skills/* ~/.claude/skills/
cp /path/to/stacked-workflow-skills/.claude/references/stacked-workflow.md \
  ~/.claude/references/stacked-workflow.md
```

#### Kiro

```bash
mkdir -p .kiro/skills .kiro/steering
ln -sfn /path/to/stacked-workflow-skills/skills/* .kiro/skills/
cp /path/to/stacked-workflow-skills/.kiro/steering/stacked-workflow.md \
  .kiro/steering/stacked-workflow.md
```

#### GitHub Copilot

```bash
mkdir -p .github/skills .github/instructions
ln -sfn /path/to/stacked-workflow-skills/skills/* .github/skills/
cp /path/to/stacked-workflow-skills/.github/instructions/stacked-workflow.instructions.md \
  .github/instructions/stacked-workflow.instructions.md
```

### All Methods

<!-- dprint-ignore -->
| Method | Best for | Details |
|--------|----------|---------|
| **Nix home-manager module** (HM >= 25.11) | Declarative per-user | `stacked-workflows.enable = true` |
| **Nix (programs.claude-code)** | Direct Claude Code config | `skills` + `home.file` references |
| **Nix overlay** | Packages only | `overlays.default` or per-package overlays |
| **Nix raw paths** | DevShells, home.file | `${inputs.stacked-workflow-skills}/skills` |
| **Manual symlink** | Non-Nix users | Symlink `skills/` into tool config dir |
| **Agentic** | AI tool self-installs | Interactive flow in `INSTALL.md` |

See **[INSTALL.md](INSTALL.md)** for detailed instructions, routing table
setup, and examples for Claude Code, Kiro, and GitHub Copilot.

#### Agentic Install

Tell your AI tool:

> Read the Agentic Installation section of INSTALL.md from
> github:higherorderfunctor/stacked-workflow-skills and follow the
> interactive install flow for this project.

The agent detects your environment, asks what to configure, skips what's
already done, and executes one step at a time with your approval.

## Git Configuration

The tools work best with specific git settings. See
`references/recommended-config.md` for the full list with explanations.

### Quick setup (manual)

```bash
# Required
git config --global init.defaultBranch main
git config --global branchless.core.mainBranch main

# Strongly recommended
git config --global absorb.fixupTargetAlwaysSHA true
git config --global absorb.maxStack 50
git config --global absorb.oneFixupPerCommit true
git config --global merge.conflictStyle zdiff3
git config --global pull.rebase true
git config --global rebase.autoSquash true
git config --global rebase.autoStash true
git config --global rebase.updateRefs true
git config --global rerere.enabled true
git config --global rerere.autoupdate true
```

### Nix (home-manager)

```nix
# Merge the preset into your git config:
programs.git.settings =
  inputs.stacked-workflow-skills.lib.gitConfig;
```

Or use the home-manager module which applies settings at `mkDefault` priority:

```nix
stacked-workflows = {
  enable = true;
  gitPreset = "full"; # or "minimal"
};
```

## License

[Unlicense](https://unlicense.org) — public domain
