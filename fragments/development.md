## Development

See `CONTRIBUTING.md` for devShell setup, global package alternatives, and
the routing file generation pipeline.

### Tool Reference Maintenance

Reference docs for dev tools live in `references/`. When tools are upgraded
(via nvfetcher) or their configuration changes, update the corresponding
reference doc. Use `/index-repo-docs <tool>` to refresh from upstream, then
curate the output.

<!-- dprint-ignore -->
| Doc                          | Covers                                           |
| ---------------------------- | ------------------------------------------------ |
| `references/agnix.md`        | agnix CLI, `.agnix.toml` config, rule categories |
| `references/nix-workflow.md` | Nix conventions, devShell, packaging patterns    |
| `references/ruler.md`        | Ruler CLI, `.ruler/` source format, profiles     |

### Nix Workflow

Nix flakes only see tracked files. Always `git add` new files before running
`nix build`, `nix develop`, `nix flake check`, or `nix eval`. See
`references/nix-workflow.md` for full conventions.
