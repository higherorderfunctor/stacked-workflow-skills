# Installation Guide

This guide covers all methods for installing stacked-workflow-skills — the
skill files, reference docs, and routing tables that tell AI tools when to
invoke each skill.

## What Gets Installed

Every method installs the **`skills/`** directory, which contains:

- **SKILL.md** files for each stack operation
- **`references/`** subdirectories with symlinks to the relevant reference
  docs for each skill's dependencies

Plus a **routing table** in your AI tool's instruction file. Skills use
`disable-model-invocation: true` — without routing rules, the model won't
invoke them.

## Routing

The routing table is generated from a single source of truth
(`lib/routing-data.nix`) and available in three formats:

<!-- dprint-ignore -->
| Platform | Pre-generated file | Instruction file |
|----------|--------------------|------------------|
| Claude Code | `.generated/claude-routing.md` | `CLAUDE.md` or `~/.claude/CLAUDE.md` |
| GitHub Copilot | `.generated/copilot-routing.md` | `.github/instructions/*.md` |
| Kiro | `.generated/kiro-routing.md` | `.kiro/steering/*.md` |

### Using pre-generated files (no Nix required)

Append the contents of the appropriate file from `.generated/` into your
project's instruction file. These are checked into the repo and kept up to
date by CI.

### Using Nix generators

All generators return strings. Evaluate directly:

```bash
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkClaudeRouting
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkCopilotInstructions
nix eval --raw github:higherorderfunctor/stacked-workflow-skills#lib.mkKiroSteering
```

## Manual Install

Symlink from a local clone so `git pull` picks up updates automatically.
Use `cp -rL` instead of `ln -sfn` if your tool doesn't follow symlinks.

### Claude Code

```bash
git clone https://github.com/higherorderfunctor/stacked-workflow-skills.git
mkdir -p ~/.claude
ln -sfn "$(pwd)/stacked-workflow-skills/skills" ~/.claude/skills
```

Then add the routing table to `~/.claude/CLAUDE.md`. Copy from
`.generated/claude-routing.md` or evaluate with `nix eval`.

The top-level `references/` directory is also useful for global CLAUDE.md
reference loading (the `RULE` about reading reference docs before running
stacked workflow commands):

```bash
ln -sfn "$(pwd)/stacked-workflow-skills/references" ~/.claude/references
```

### Claude Code (Per-Project)

```bash
mkdir -p .claude
ln -sfn /path/to/stacked-workflow-skills/skills .claude/skills
```

Add the routing table to the project's `CLAUDE.md`.

### Kiro

```bash
mkdir -p .kiro/steering .kiro/skills
ln -sfn /path/to/stacked-workflow-skills/skills/* .kiro/skills/
```

Copy `.generated/kiro-routing.md` to `.kiro/steering/stacked-workflow.md`.

### GitHub Copilot

```bash
mkdir -p .github/instructions .github/skills
ln -sfn /path/to/stacked-workflow-skills/skills/* .github/skills/
```

Copy `.generated/copilot-routing.md` to
`.github/instructions/stacked-workflow.instructions.md` and add `applyTo: "**"`
YAML frontmatter.

## Nix: programs.claude-code (Home-Manager >= 25.11)

The upstream `programs.claude-code` module handles skill installation
directly — no custom module needed.

Add the flake input:

```nix
{
  inputs.stacked-workflow-skills.url = "github:higherorderfunctor/stacked-workflow-skills";
}
```

Configure in your home-manager config:

```nix
programs.claude-code = {
  enable = true;
  skillsDir = "${inputs.stacked-workflow-skills}/skills";
  memory.text = lib.mkAfter (import "${inputs.stacked-workflow-skills}/lib/routing-claude.nix");
};

# Top-level references for global CLAUDE.md reference loading (optional)
home.file.".claude/references".source = "${inputs.stacked-workflow-skills}/references";
```

## Nix: Raw Paths

Use the flake paths directly in `home.file`, shellHooks, or any Nix
expression:

```nix
{
  inputs.stacked-workflow-skills.url = "github:higherorderfunctor/stacked-workflow-skills";
}

# Example: home.file
home.file.".claude/skills".source =
  "${inputs.stacked-workflow-skills}/skills";

# Optional: top-level references for global CLAUDE.md
home.file.".claude/references".source =
  "${inputs.stacked-workflow-skills}/references";
```

### DevShell (Per-Project)

Symlink skills in a shellHook:

```nix
devShells.default = pkgs.mkShellNoCC {
  shellHook = ''
    mkdir -p .claude/skills
    ln -sfn ${inputs.stacked-workflow-skills}/skills/* .claude/skills/
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
   - **programs.claude-code** — set `skillsDir` and `memory.text` (see
     [Nix: programs.claude-code](#nix-programsclaude-code-home-manager--2511))
   - **DevShell** — add shellHook symlinks (see
     [DevShell (Per-Project)](#devshell-per-project))
   - **Raw paths** — use `home.file` (see [Nix: Raw Paths](#nix-raw-paths))
3. Add the routing table to `CLAUDE.md` using `lib.mkClaudeRouting`
4. Optionally add git config:
   `programs.git.extraConfig = inputs.stacked-workflow-skills.lib.gitConfig;`

### Claude Code — Non-Nix Project

The agent should:

1. Clone the repo
2. Symlink `skills/` to `.claude/skills`
3. Add the routing table to the project's `CLAUDE.md`

### Kiro / Copilot

Follow the respective manual section above. The agent can evaluate the
routing generator via `nix eval` if Nix is available, or copy the pre-generated
routing file from `.generated/`.
