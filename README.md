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

Distilled docs for each tool — command reference, recipes, anti-patterns,
integration notes:

- `references/philosophy.md` — atomic commit principles and ordering conventions
- `references/git-branchless.md` — smartlog, move, sync, submit, revsets
- `references/git-absorb.md` — automatic fixup routing
- `references/git-revise.md` — in-memory commit rewriting

## Prerequisites

- [git-branchless](https://github.com/arxanas/git-branchless)
- [git-absorb](https://github.com/tummychow/git-absorb)
- [git-revise](https://github.com/mystor/git-revise) (optional, used by some
  recipes)

### Manual install

```bash
cargo install --git https://github.com/arxanas/git-branchless git-branchless
cargo install --git https://github.com/tummychow/git-absorb
# Optional:
pip install git-revise
```

### Nix overlay

This flake provides an overlay with packages built from the latest release
sources (tracked via nvfetcher). Use per-package overlays for selective
installation:

```nix
{
  inputs.stacked-workflow-skills.url = "github:higherorderfunctor/stacked-workflow-skills";
}

# In your configuration or home-manager:
nixpkgs.overlays = [
  inputs.stacked-workflow-skills.overlays.git-branchless
];
# Then use pkgs.git-branchless anywhere
```

Or use the combined overlay for all tools:

```nix
nixpkgs.overlays = [
  inputs.stacked-workflow-skills.overlays.default
];
```

Or with `nix develop` (provides all three tools):

```bash
nix develop github:higherorderfunctor/stacked-workflow-skills
```

Optional: [direnv](https://direnv.net/) with
[nix-direnv](https://github.com/nix-community/nix-direnv) to automatically
load the flake dev shell (`.envrc` uses `use flake` which requires nix-direnv).

## Installation

### Claude Code — manual (per-user)

Copy or symlink into your global Claude Code config:

```bash
# Skills (copy contents, not the directory itself)
mkdir -p ~/.claude/skills ~/.claude/references
cp -r skills/* ~/.claude/skills/

# References (skills load these on demand)
cp -r references/* ~/.claude/references/
```

Then add the routing table to your `~/.claude/CLAUDE.md` (or the project's
`CLAUDE.md`) — see [Routing](#routing) below.

### Claude Code — manual (per-project)

For a specific project, copy into the project's `.claude/` directory:

```bash
mkdir -p .claude/skills .claude/references
cp -r skills/* .claude/skills/
cp -r references/* .claude/references/
```

Add the routing table to the project's `CLAUDE.md`.

### Claude Code — Nix home-manager

Add this repo as a flake input and use the home-manager module (coming soon):

```nix
{
  inputs.stacked-workflow-skills.url = "github:higherorderfunctor/stacked-workflow-skills";
}
```

### Other AI Tools (Kiro, Copilot, etc.)

Copy skills into the tool's skill/agent directory and add routing rules per
the tool's instruction mechanism. See [Routing](#routing) below for the
routing table to adapt.

## Routing

**This is the critical step.** Skills with `disable-model-invocation: true`
are not auto-activated by model descriptions alone. You must add routing rules
to your CLAUDE.md (or equivalent instruction file) so the model knows when to
invoke them.

Add this table to your `CLAUDE.md`:

```markdown
## Skill Routing — MANDATORY

When working with stacked commits, use the appropriate skill instead of
running commands manually via Bash.

| Operation | Skill | Use INSTEAD of |
|-----------|-------|----------------|
| Fix lines in earlier commit | `/stack-fix` | `git absorb`, `git commit --fixup` |
| Edit earlier commit (content moves) | `/stack-fix` | Manual checkout + amend + restack |
| Plan and build a commit stack | `/stack-plan` | Ad-hoc commits without a plan |
| Restructure/reorder commits | `/stack-plan` | `git rebase -i`, `git reset --soft` |
| Commit uncommitted work as stack | `/stack-plan` | Single monolithic commit |
| Split a large commit | `/stack-split` | `git rebase -i` + edit |
| Audit stack quality | `/stack-summary` | Manual `git log` inspection |
| Push stack for review | `/stack-submit` | Manual `git sync` + `git submit` + `gh pr create` |
| Test across stack | `/stack-test` | Manual `git test run` |
```

Without this routing table, the model will default to running raw git commands
instead of invoking the skills.

## License

[Unlicense](https://unlicense.org) — public domain
