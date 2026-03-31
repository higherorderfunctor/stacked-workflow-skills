### Formatting

After editing any file — regardless of how it was modified (Edit, Write,
Bash, sed, etc.) — run `dprint fmt <file>` on the changed file. dprint
handles markdown, JSON, and Nix (via alejandra). The PostToolUse hook
auto-formats after Edit/Write, but Bash edits bypass hooks. Always format
explicitly after Bash-based file modifications.

### Validation

After creating or modifying any SKILL.md, AGENTS.md, CLAUDE.md, `.mcp.json`,
or `.agnix.toml`, validate with agnix before committing. The pre-commit hook
runs `agnix --strict .` automatically on staged config files, but proactive
validation catches issues earlier.

Do not install packages globally — use tools available in the devShell. If
something is missing, ask the user or use `npx`/`uvx`/`nix run` instead.

If the Skill tool invocation fails (e.g., due to `disable-model-invocation`
or platform limitations), read the SKILL.md file directly and execute its
instructions step by step. The routing table is MANDATORY — skills must be
used even when the tool mechanism is unavailable.
