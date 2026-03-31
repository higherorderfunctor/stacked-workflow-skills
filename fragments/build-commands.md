## Build & Dev Commands

```bash
nix develop          # Enter devShell (git-branchless, git-absorb, git-revise)
dprint fmt           # Format all files (markdown, JSON, Nix via alejandra)
nix flake check      # Validate flake, formatting, spelling, and agent configs
agnix --strict .     # Lint AI agent config files
```

**Note:** `nix flake check` only includes tracked files — see
[Nix Workflow](#nix-workflow) below.
