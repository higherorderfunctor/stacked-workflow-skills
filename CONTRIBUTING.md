# Contributing

## Development Environment

### Nix (recommended)

```bash
nix develop
```

Provides all tools: git-branchless, git-absorb, git-revise, agnix,
alejandra, dprint, cspell, nvfetcher.

### Without Nix

The following tools are required. Check which are available, then install
any that are missing using your preferred method:

**Required tools:**

<!-- dprint-ignore -->
| Tool | Purpose | Upstream |
|------|---------|----------|
| [git-branchless](https://github.com/arxanas/git-branchless) | Stacked commits | Rust binary |
| [git-absorb](https://github.com/tummychow/git-absorb) | Fixup absorption | Rust binary |
| [git-revise](https://github.com/mystor/git-revise) | Commit editing | Python package |
| [agnix](https://github.com/agent-sh/agnix) | Agent config linting | Rust/npm |
| [dprint](https://dprint.dev) | Formatting | Rust binary |
| [alejandra](https://github.com/kamadorueda/alejandra) | Nix formatting | Rust binary |

**Prereq check** (run this to see what's missing):

```bash
for tool in git-branchless git-absorb git-revise agnix dprint alejandra; do
  command -v "$tool" &>/dev/null && echo "✓ $tool" || echo "✗ $tool — not found"
done
```

Install missing tools however you prefer — package manager, cargo, npm,
pipx, system packages, or ask your AI assistant to help find the right
install method for your environment.

## Validation

Run before committing:

```bash
dprint fmt           # format all files (markdown, JSON, Nix via alejandra)
agnix --strict .     # lint agent configs
cspell lint '**/*.md' --no-progress  # spellcheck
nix flake check      # all checks (requires staged files)
```

## Generating Instruction Files

All instruction content lives as composable markdown fragments in
`fragments/`. A Nix app generates per-ecosystem outputs with appropriate
frontmatter and placement:

```bash
nix run .#generate
```

This produces:

- `.claude/references/stacked-workflow.md` — Claude (no frontmatter)
- `.kiro/steering/stacked-workflow.md` — Kiro (`inclusion: auto`)
- `.github/instructions/stacked-workflow.instructions.md` — Copilot (`applyTo`)
- `AGENTS.md` — generated from dev profile fragments

Profiles (package vs dev) and ecosystem config are declared in
`lib/fragments.nix`. Run after modifying `fragments/` source files.
The pre-commit hook auto-regenerates when fragments are staged.

## Reference Docs

Tool-specific reference docs live in `references/`:

| Doc                            | Covers                               |
| ------------------------------ | ------------------------------------ |
| `references/agnix.md`          | agnix CLI, config, rule categories   |
| `references/nix-workflow.md`   | Nix conventions, devShell, packaging |
| `references/git-branchless.md` | git-branchless commands, revsets     |
| `references/git-absorb.md`     | git-absorb usage and patterns        |
| `references/git-revise.md`     | git-revise usage                     |
| `references/philosophy.md`     | Stacked workflow principles          |

**Maintenance**: when dev tools are upgraded (via nvfetcher) or config
changes, update the corresponding `references/<tool>.md`. Use
`/index-repo-docs <tool>` to refresh from upstream docs.
