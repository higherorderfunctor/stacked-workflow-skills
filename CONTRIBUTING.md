# Contributing

## Development Environment

### Nix (recommended)

```bash
nix develop
```

Provides all tools: git-branchless, git-absorb, git-revise, agnix, ruler,
alejandra, dprint, cspell, nvfetcher.

### Without Nix

Install these globally:

| Tool                                                        | Purpose              | Install                                             |
| ----------------------------------------------------------- | -------------------- | --------------------------------------------------- |
| [agnix](https://github.com/agent-sh/agnix)                  | Agent config linting | `npm install -g agnix` or `cargo install agnix-cli` |
| [ruler](https://github.com/intellectronica/ruler)           | Rule distribution    | `npm install -g @intellectronica/ruler`             |
| [git-branchless](https://github.com/arxanas/git-branchless) | Stacked commits      | `cargo install --locked git-branchless`             |
| [git-absorb](https://github.com/tummychow/git-absorb)       | Fixup absorption     | `cargo install git-absorb`                          |
| [git-revise](https://github.com/mystor/git-revise)          | Commit editing       | `pipx install git-revise`                           |

<!-- TODO: explore npx/uvx for dev tool execution without global installs -->

## Validation

Run before committing:

```bash
nix fmt              # or: alejandra .
agnix --strict .     # lint agent configs
cspell lint '**/*.md' --no-progress  # spellcheck
nix flake check      # all checks (requires staged files)
```

## Generating Routing Files

The routing table is maintained in `.ruler/` and distributed to all
ecosystems via `scripts/generate.sh`:

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
