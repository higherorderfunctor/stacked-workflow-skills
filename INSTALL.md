# Installation Guide

This guide covers all methods for installing stacked-workflow-skills — the
skill files, reference docs, and routing tables that tell AI tools when to
invoke each skill.

## What Gets Installed

Every method installs these two directories:

- **`skills/`** — SKILL.md files for each stack operation
- **`references/`** — distilled docs for git-branchless, git-absorb, git-revise

Plus a **routing table** in your AI tool's instruction file. Skills use
`disable-model-invocation: true` — without routing rules, the model won't
invoke them.

## Routing

The routing table is generated from a single source of truth
(`lib/routing-data.nix`) and available in three platform formats:

<!-- dprint-ignore -->
| Platform | Generator | Instruction file |
|----------|-----------|------------------|
| Claude Code | `lib.mkClaudeRouting` | `CLAUDE.md` or `~/.claude/CLAUDE.md` |
| Kiro | `lib.mkKiroSteering` | `.kiro/steering/*.md` |
| GitHub Copilot | `lib.mkCopilotInstructions` | `.github/instructions/*.md` |

All generators return strings. Use them in Nix expressions or evaluate
directly:

```bash
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkClaudeRouting
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkKiroSteering
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkCopilotInstructions
```

## Nix: Raw Paths

The flake exposes skill and reference directories as paths. Use them in
`home.file`, shellHooks, or any Nix expression:

```nix
{
  inputs.stacked-workflow-skills.url = "github:higherorderfunctor/stacked-workflow-skills";
}

# Example: home.file
home.file.".claude/skills".source =
  "${inputs.stacked-workflow-skills}/skills";
home.file.".claude/references".source =
  "${inputs.stacked-workflow-skills}/references";
```

### DevShell (Per-Project)

Symlink skills and references in a shellHook:

```nix
devShells.default = pkgs.mkShellNoCC {
  shellHook = ''
    mkdir -p .claude/skills .claude/references
    ln -sfn ${inputs.stacked-workflow-skills}/skills/* .claude/skills/
    ln -sfn ${inputs.stacked-workflow-skills}/references/* .claude/references/
  '';
};
```

Add the routing table to the project's `CLAUDE.md` (or equivalent). Use
`lib.mkClaudeRouting` in a Nix expression, or evaluate it and paste.

### Git Configuration (Optional)

The flake provides git config presets for stacked workflows:

```nix
# Minimal (required + strongly recommended):
programs.git.extraConfig = inputs.stacked-workflow-skills.lib.gitConfig;

# Full (all recommended settings):
programs.git.extraConfig = inputs.stacked-workflow-skills.lib.gitConfigFull;
```

## Manual: Claude Code

### Per-User

```bash
git clone https://github.com/higherorderfunctor/stacked-workflow-skills.git
cd stacked-workflow-skills

mkdir -p ~/.claude/skills ~/.claude/references
cp -r skills/* ~/.claude/skills/
cp -r references/* ~/.claude/references/
```

Then add the routing table to `~/.claude/CLAUDE.md`. Generate it with:

```bash
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkClaudeRouting
```

Paste the output into your CLAUDE.md.

### Per-Project

```bash
mkdir -p .claude/skills .claude/references
cp -r /path/to/stacked-workflow-skills/skills/* .claude/skills/
cp -r /path/to/stacked-workflow-skills/references/* .claude/references/
```

Add the routing table to the project's `CLAUDE.md`.

## Manual: Kiro

Copy skills and references into your project:

```bash
mkdir -p .kiro/skills .kiro/references
cp -r /path/to/stacked-workflow-skills/skills/* .kiro/skills/
cp -r /path/to/stacked-workflow-skills/references/* .kiro/references/
```

Create a steering file with the routing rules. Evaluate the Kiro format:

```bash
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkKiroSteering
```

Or copy the output into `.kiro/steering/stacked-workflow.md`.

## Manual: GitHub Copilot

Copy skills and references into your project:

```bash
mkdir -p .github/skills .github/references
cp -r /path/to/stacked-workflow-skills/skills/* .github/skills/
cp -r /path/to/stacked-workflow-skills/references/* .github/references/
```

Create an instructions file with the routing rules. Evaluate the Copilot
format:

```bash
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkCopilotInstructions
```

Or copy the output into `.github/instructions/stacked-workflow.instructions.md`.

## Agentic Installation

AI tools (Claude Code, Kiro, Copilot) can perform the manual installation
steps autonomously. Point the tool at this guide:

> Read `INSTALL.md` from
> `github:higherorderfunctor/stacked-workflow-skills` and follow the
> appropriate installation method for this project.

### Claude Code — Nix Project

If the project has a `flake.nix`, the agent should:

1. Add the flake input:
   ```nix
   inputs.stacked-workflow-skills.url = "github:higherorderfunctor/stacked-workflow-skills";
   ```
2. Choose an integration path:
   - **DevShell** — add shellHook symlinks (see
     [DevShell (Per-Project)](#devshell-per-project))
   - **Raw paths** — use `home.file` (see [Nix: Raw Paths](#nix-raw-paths))
3. Add the routing table to `CLAUDE.md` using `lib.mkClaudeRouting`
4. Optionally add git config: `programs.git.extraConfig = inputs.stacked-workflow-skills.lib.gitConfig;`

### Claude Code — Non-Nix Project

The agent should:

1. Clone or download the skill files
2. Copy `skills/*` to `.claude/skills/` and `references/*` to `.claude/references/`
3. Add the routing table to the project's `CLAUDE.md`

### Kiro / Copilot

Follow the respective manual section above. The agent can evaluate the
routing generator via `nix eval` if Nix is available, or copy the routing
table from this guide.
