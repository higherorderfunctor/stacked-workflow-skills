# Installation Guide

This guide covers all methods for installing stacked-workflow-skills — the
skill files, reference docs, and routing tables that tell AI tools when to
invoke each skill.

## What Gets Installed

Every method installs the **`skills/`** directory, which contains:

- **SKILL.md** files for each stack operation
- **`references/`** subdirectories with symlinks to the relevant reference
  docs for each skill's dependencies

Plus a **routing table** in your AI tool's instruction file. The routing
table reinforces when to invoke each skill.

## Routing

The routing table is maintained in `.ruler/routing.md` and generated into
per-ecosystem formats by `scripts/generate.sh`:

<!-- dprint-ignore -->
| Platform | Pre-generated file | Instruction file |
|----------|--------------------|------------------|
| Claude Code | `.generated/claude-routing.md` | `CLAUDE.md` or `~/.claude/CLAUDE.md` |
| GitHub Copilot | `.generated/copilot-routing.md` | `.github/instructions/*.md` |
| Kiro | `.generated/kiro-routing.md` | `.kiro/steering/*.md` |

### Using pre-generated files (no Nix required)

Copy the appropriate file from `.generated/` into your project's instruction
file location. Kiro and Copilot files include YAML frontmatter — use the
file as-is. These are checked into the repo and kept in sync by CI.

### Using Nix lib (pass-through)

The Nix lib functions read from `.generated/` and return strings. Useful
for wiring into home-manager or other Nix expressions:

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

The module provides a single `stacked-workflows` option that
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

stacked-workflows = {
  enable = true;
  gitPreset = "full"; # "full" | "minimal" | "none"

  integrations = {
    claude.enable = true;  # requires programs.claude-code.enable = true
    # kiro.enable = true;   # places files in ~/.kiro/
    # copilot.enable = true; # places files in ~/.copilot/
  };
};
```

### Module Options

<!-- dprint-ignore -->
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `stacked-workflows.enable` | bool | `false` | Enable the module |
| `stacked-workflows.gitPreset` | enum | `"none"` | Git config preset (`"full"`, `"minimal"`, `"none"`) — sets `programs.git.settings` at `mkDefault` priority |
| `stacked-workflows.integrations.claude.enable` | bool | `false` | Claude Code — sets per-skill entries, routing, references |
| `stacked-workflows.integrations.copilot.enable` | bool | `false` | Copilot CLI (`gh copilot`) — places skills + instructions in `~/.copilot/` |
| `stacked-workflows.integrations.kiro.enable` | bool | `false` | Kiro — places skills + steering in `~/.kiro/` |

### Packages

The module configures git settings and skill routing but does **not** add
`git-absorb`, `git-branchless`, or `git-revise` to `home.packages`. The
overlay makes version-tracked builds available in nixpkgs — you still need
to include them in your packages list:

```nix
home.packages = with pkgs; [git-absorb git-branchless git-revise];
```

### Known conflicts

<!-- dprint-ignore -->
| Your setting | Module setting | Problem | Fix |
|-------------|---------------|---------|-----|
| `pull.ff = "only"` | `pull.rebase = true` | `pull.ff` wins since Git 2.34, breaking `git pull` | Remove `pull.ff` from your config |
| `home.file.".claude/references"` | same path | Conflicting `home.file` definitions | Set `integrations.claude.enable = false` and manage references separately |

The module asserts against `pull.ff` at evaluation time — you'll get a clear
error message if it's set.

### What each option does

**`gitPreset = "minimal"`** — sets `programs.git.settings` with required +
strongly recommended settings (branchless main branch, absorb config,
merge/pull/rebase defaults, rerere). All values at `mkDefault` priority so
your overrides win.

**`gitPreset = "full"`** — adds recommended settings on top of minimal
(branchless smartlog/test/navigation, revise autoSquash, histogram diff,
fetch pruning, push defaults).

**`integrations.claude.enable`** — requires `programs.claude-code.enable =
true`. Sets per-skill `programs.claude-code.skills` entries (additive —
merges with your personal skills), appends routing table to
`programs.claude-code.memory.text`, places per-file references in
`~/.claude/references/`. Note: if you already manage `~/.claude/references`
via `home.file` (e.g., outOfStoreSymlinks), don't enable this — it will
conflict. Use the [direct](#nix-programsclaude-code-direct) method instead.

**`integrations.kiro.enable`** — symlinks skills to `~/.kiro/skills/`,
places routing steering file at `~/.kiro/steering/stacked-workflow.md`.

**`integrations.copilot.enable`** — Copilot CLI only (`gh copilot`).
Symlinks skills to `~/.copilot/skills/`, places routing instructions at
`~/.copilot/copilot-instructions.md`. Editor-specific Copilot config
(VS Code, JetBrains, etc.) is out of scope — use per-project install.

### Migrating from manual symlinks

If you previously used `outOfStoreSymlinks` or `ln -sfn` to manage
`~/.claude/skills` and `~/.claude/references`, you must clean up before
activating the module:

```bash
rm -f ~/.claude/skills ~/.claude/references
```

Home-manager won't remove symlinks it didn't create. Stale symlinks can
cause the new store paths to write through into the repo directory. After
removing them, run `home-manager switch` (or `nixos-rebuild switch`) to
let the module create the correct entries.

The module uses `programs.claude-code.skills` (per-skill attrset) and
individual `home.file` entries for references, so your personal skills
and references from other modules coexist without conflicts.

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
  skills = {
    stack-fix = "${inputs.stacked-workflow-skills}/skills/stack-fix";
    stack-plan = "${inputs.stacked-workflow-skills}/skills/stack-plan";
    stack-split = "${inputs.stacked-workflow-skills}/skills/stack-split";
    stack-submit = "${inputs.stacked-workflow-skills}/skills/stack-submit";
    stack-summary = "${inputs.stacked-workflow-skills}/skills/stack-summary";
    stack-test = "${inputs.stacked-workflow-skills}/skills/stack-test";
  };
  memory.text = lib.mkAfter (import "${inputs.stacked-workflow-skills}/lib/routing-claude.nix");
};

# Per-file references for global CLAUDE.md reference loading (optional)
home.file.".claude/references/git-absorb.md".source = "${inputs.stacked-workflow-skills}/references/git-absorb.md";
home.file.".claude/references/git-branchless.md".source = "${inputs.stacked-workflow-skills}/references/git-branchless.md";
home.file.".claude/references/git-revise.md".source = "${inputs.stacked-workflow-skills}/references/git-revise.md";
home.file.".claude/references/philosophy.md".source = "${inputs.stacked-workflow-skills}/references/philosophy.md";
home.file.".claude/references/recommended-config.md".source = "${inputs.stacked-workflow-skills}/references/recommended-config.md";
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
- [ ] ~/.claude/ managed by existing home.file or outOfStoreSymlinks
```

Tell the user what you found and what's missing.

**If `~/.claude/` is already managed** (e.g., via `home.file` or
`outOfStoreSymlinks`), warn the user before Step 4:

> Your `~/.claude/` directory is already managed by your home-manager
> config. Enabling `integrations.claude` will conflict with existing
> `home.file.".claude/references"` definitions. You have two options:
>
> 1. Skip the claude integration (`integrations.claude.enable` stays
>    `false`) and wire `programs.claude-code.skills` + `memory.text`
>    manually (see [Nix: programs.claude-code (Direct)](#nix-programsclaude-code-direct))
> 2. Remove your existing `~/.claude/references` management and let the
>    module handle it via `integrations.claude.enable = true`

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
> 1. **Home-manager module** — `stacked-workflows.enable = true`
>    (best for personal machine setup, configures git + ecosystems declaratively)
> 2. **programs.claude-code** — direct skills + memory.text
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
stacked-workflows = {
  enable = true;
  gitPreset = "full"; # "full" | "minimal" | "none" — ask the user
};
```

Ask the user which ecosystems to enable. All must be explicitly enabled:

> Which AI tools do you use?
>
> - Claude Code (requires programs.claude-code.enable = true)
> - Kiro (places files in ~/.kiro/)
> - Copilot CLI (places files in ~/.copilot/)

Ask which git config preset:

> Git config preset? This sets `programs.git.settings` at `mkDefault`
> priority — your existing overrides win.
>
> - **full** — all recommended settings (branchless, absorb, revise, diff, fetch, push)
> - **minimal** — required + strongly recommended only
> - **none** — no git config changes

**programs.claude-code (option 2):**

See [Nix: programs.claude-code (Direct)](#nix-programsclaude-code-direct).
Wire `skills`, `memory.text`, and optionally `home.file` for references.

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
