# Contributing

## Development Environment

### Nix (recommended)

```bash
nix develop
```

Provides all tools: git-branchless, git-absorb, git-revise, agnix, ruler,
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
| [ruler](https://github.com/intellectronica/ruler) | Rule distribution | npm |
| [dprint](https://dprint.dev) | Formatting | Rust binary |
| [alejandra](https://github.com/kamadorueda/alejandra) | Nix formatting | Rust binary |

**Prereq check** (run this to see what's missing):

```bash
for tool in git-branchless git-absorb git-revise agnix ruler dprint alejandra; do
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

## Generating Routing Files

The routing table is maintained in `.ruler/` and distributed to all
ecosystems via `scripts/generate.sh` (not `ruler apply` — ruler cannot
inject per-ecosystem YAML frontmatter or produce consumer vs dev output
variants; see `references/ruler.md` for details):

```bash
scripts/generate.sh
```

This produces:

- **In-repo files** — `.kiro/steering/stacked-workflow.md`,
  `.github/instructions/stacked-workflow.instructions.md`
- **Published files** — `.generated/claude-routing.md`,
  `.generated/kiro-routing.md`, `.generated/copilot-routing.md`

Run after modifying `.ruler/` source files.

## Reference Docs

Tool-specific reference docs live in `references/`:

| Doc                            | Covers                               |
| ------------------------------ | ------------------------------------ |
| `references/agnix.md`          | agnix CLI, config, rule categories   |
| `references/ruler.md`          | Ruler CLI, config, source format     |
| `references/nix-workflow.md`   | Nix conventions, devShell, packaging |
| `references/git-branchless.md` | git-branchless commands, revsets     |
| `references/git-absorb.md`     | git-absorb usage and patterns        |
| `references/git-revise.md`     | git-revise usage                     |
| `references/philosophy.md`     | Stacked workflow principles          |

**Maintenance**: when dev tools are upgraded (via nvfetcher) or config
changes, update the corresponding `references/<tool>.md`. Use
`/index-repo-docs <tool>` to refresh from upstream docs.
