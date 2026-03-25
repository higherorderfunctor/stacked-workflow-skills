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

## Nix: Home-Manager Module

The module provides a single `programs.stacked-workflow-skills` option that
configures git settings, Claude Code, Kiro, and Copilot integration. This is
for global/per-user setup only — per-project install should use a devShell or
manual symlinks.

Add the flake input and import the module:

```nix
{
  inputs.stacked-workflow-skills = {
    url = "github:higherorderfunctor/stacked-workflow-skills";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}

# In your home-manager config:
imports = [ inputs.stacked-workflow-skills.homeManagerModules.default ];

programs.stacked-workflow-skills = {
  enable = true;
  git = "full"; # "full" | "minimal" | "none"
  # claude.enable auto-detected from programs.claude-code.enable
  # kiro.enable = true;   # places files in ~/.kiro/
  # copilot.enable = true; # places files in ~/.copilot/
};
```

### Module Options

<!-- dprint-ignore -->
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `programs.stacked-workflow-skills.enable` | bool | `false` | Enable skill installation |
| `programs.stacked-workflow-skills.git` | enum | `"none"` | Git config preset (`"full"`, `"minimal"`, `"none"`) — sets `programs.git.settings` at `mkDefault` priority |
| `programs.stacked-workflow-skills.claude.enable` | bool | auto | Claude Code integration (auto-detected from `programs.claude-code.enable`) |
| `programs.stacked-workflow-skills.copilot.enable` | bool | `false` | Copilot CLI (`gh copilot`) — places skills + instructions in `~/.copilot/` |
| `programs.stacked-workflow-skills.kiro.enable` | bool | `false` | Kiro — places skills + steering in `~/.kiro/` |

### What each option does

**`git = "minimal"`** — sets `programs.git.settings` with required + strongly
recommended settings (branchless main branch, absorb config, merge/pull/rebase
defaults, rerere). All values at `mkDefault` priority so your overrides win.

**`git = "full"`** — adds recommended settings on top of minimal (branchless
smartlog/test/navigation, revise autoSquash, histogram diff, fetch pruning,
push defaults).

**`claude.enable`** — sets `programs.claude-code.skillsDir`, appends routing
table to `programs.claude-code.memory.text`, symlinks `references/` to
`~/.claude/references/`.

**`kiro.enable`** — symlinks skills to `~/.kiro/skills/`, places routing
steering file at `~/.kiro/steering/stacked-workflow.md`.

**`copilot.enable`** — Copilot CLI only (`gh copilot`). Symlinks skills to
`~/.copilot/skills/`, places routing instructions at
`~/.copilot/copilot-instructions.md`. Editor-specific Copilot config (VS Code,
JetBrains, etc.) is out of scope — use per-project install for those.

## Nix: programs.claude-code (Direct)

If you prefer not to use the module, configure `programs.claude-code` directly:

```nix
{
  inputs.stacked-workflow-skills = {
    url = "github:higherorderfunctor/stacked-workflow-skills";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}

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
  inputs.stacked-workflow-skills = {
    url = "github:higherorderfunctor/stacked-workflow-skills";
    inputs.nixpkgs.follows = "nixpkgs";
  };
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
programs.git.settings = inputs.stacked-workflow-skills.lib.gitConfig;

# Full (all recommended settings):
programs.git.settings = inputs.stacked-workflow-skills.lib.gitConfigFull;
```

**Note:** These set values at normal priority. To use `mkDefault` priority
(so your other config wins), use the home-manager module's `git` option
instead, or wrap with `lib.mapAttrsRecursive (_: lib.mkDefault)`.

## Agentic Installation

AI tools can install stacked-workflow-skills interactively. The agent
detects the project environment, asks what to configure, skips anything
already done, and executes one step at a time with confirmation.

### How to start

Give your AI tool this prompt:

> Read the Agentic Installation section of INSTALL.md from
> github:higherorderfunctor/stacked-workflow-skills and follow the
> interactive install flow for this project.

### Agent instructions

Follow this flow. Each step has a guard — skip steps that are already done.
Ask the user before making changes. Do not batch steps silently.

#### Step 1: Detect environment

Check the project and report what you find:

```
- [ ] flake.nix exists → Nix project
- [ ] home-manager config detected → HM module path available
- [ ] .claude/ exists → Claude Code configured
- [ ] .kiro/ exists → Kiro configured
- [ ] .github/ exists → Copilot possible
- [ ] stacked-workflow-skills already in flake inputs
- [ ] skills already installed (check for stack-fix, stack-plan, etc.)
- [ ] routing table already in instruction file
```

Tell the user what you found and what's missing.

#### Step 2: Add flake input (Nix projects only)

**Guard:** skip if `stacked-workflow-skills` is already in flake inputs.

Add the input with `nixpkgs.follows` (nvfetcher is dev-only — no need to
follow it):

```nix
inputs.stacked-workflow-skills = {
  url = "github:higherorderfunctor/stacked-workflow-skills";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Run `nix flake lock --update-input stacked-workflow-skills` to fetch.

#### Step 3: Choose integration method

Ask the user:

> How would you like to install the skills?
>
> 1. **Home-manager module** — `programs.stacked-workflow-skills.enable = true`
>    (best for personal machine setup, configures git + ecosystems declaratively)
> 2. **programs.claude-code** — direct skillsDir + memory.text
>    (if you already configure Claude Code via HM and want manual control)
> 3. **DevShell** — per-project shellHook symlinks
>    (skills available only when `nix develop` is active)
> 4. **Manual symlinks** — for non-Nix projects

For non-Nix projects, skip to step 5.

#### Step 4: Wire up the chosen method

**Home-manager module (option 1):**

```nix
# Add to imports:
imports = [ inputs.stacked-workflow-skills.homeManagerModules.default ];

# Configure:
programs.stacked-workflow-skills = {
  enable = true;
  git = "full"; # "full" | "minimal" | "none" — ask the user
};
```

Ask the user which ecosystems to enable. `claude.enable` auto-detects from
`programs.claude-code.enable`. Kiro and Copilot must be explicitly enabled:

> Which AI tools do you use?
> - Claude Code (auto-detected if programs.claude-code.enable is true)
> - Kiro (places files in ~/.kiro/)
> - Copilot CLI (places files in ~/.copilot/)

Ask which git config preset:

> Git config preset? This sets `programs.git.settings` at `mkDefault`
> priority — your existing overrides win.
> - **full** — all recommended settings (branchless, absorb, revise, diff, fetch, push)
> - **minimal** — required + strongly recommended only
> - **none** — no git config changes

**programs.claude-code (option 2):**

See [Nix: programs.claude-code (Direct)](#nix-programsclaude-code-direct).
Wire `skillsDir`, `memory.text`, and optionally `home.file` for references.

**DevShell (option 3):**

See [DevShell (Per-Project)](#devshell-per-project). Add shellHook symlinks
and routing table to the project's `CLAUDE.md`.

**Manual symlinks (option 4):**

See [Manual Install](#manual-install). Clone, symlink, add routing table.

#### Step 5: Add routing table (non-HM-module paths only)

**Guard:** skip if using the HM module (it adds the routing table
automatically via `programs.claude-code.memory.text`).

**Guard:** skip if the routing table is already in the instruction file.

For Claude Code, append to `CLAUDE.md`:
```bash
cat .generated/claude-routing.md >> CLAUDE.md
# or for global:
cat .generated/claude-routing.md >> ~/.claude/CLAUDE.md
```

For Kiro, copy `.generated/kiro-routing.md` to `.kiro/steering/`.

For Copilot, copy `.generated/copilot-routing.md` to
`.github/instructions/`.

#### Step 6: Verify

Run a quick check to confirm skills are working:

```
- [ ] Skills directory exists and contains SKILL.md files
- [ ] Routing table is in the instruction file
- [ ] /stack-summary responds (invoke it to test)
```

If using the HM module, remind the user to rebuild:
```bash
# NixOS:
sudo nixos-rebuild switch

# Home-manager standalone:
home-manager switch
```

Then verify in a new terminal/session.

### Human walkthrough

The steps above also serve as a human checklist. If you're installing
manually, follow steps 1-6 — the guards tell you what to skip, and the
questions help you choose the right method for your setup.
