# NixOS configuration todos

Working notes for the audit of `NixSama` (`/home/spamdoodler/nixos`). These
files are planning documents only. **No configuration change is approved just
because it appears here.** Mark an item done only after it is implemented and
verified.

## Conventions

- `[ ]` not started
- `[~]` in progress / blocked
- `[x]` done and verified
- `P0` security or data-loss risk
- `P1` correctness, reliability, or notable waste
- `P2` comfort, polish, or optional experiment

Each topic file contains: current state, decisions already made, actionable
tasks, verification commands, and open questions. Commands assume the repo is
at `/home/spamdoodler/nixos` and the host is `NixSama`.

## Locked decisions

- **Bleeding edge takes priority over tidiness.** Improve cleanliness, best
  practice, and maintainability through clear ownership, reproducible checks,
  and short-lived workarounds—not a stable-channel migration or unnecessary
  abstractions. See `maintainability.md` for the 2026-11-09 repository audit.
- **No LUKS/FDE for now.** Recovery risk is unacceptable. Mitigate with a lock
  screen, BIOS password, encrypted backups, minimal secrets on disk, and a
  documented recovery plan.
- **Keep `linux_testing`.** Intentional choice.
- **Keep `texliveFull`.**
- **Keep `patches.nix`.** It is a temporary build-failure escape hatch.
- **Keep TTY1 login + `start-hyprland`.** Sway must remain startable as fallback.
- **Do not touch Sway** until its `Virtual-1` issue is tested separately.
- **Keep Waybar.** Keep seconds in the clock; measure before optimising.
- **Keep the 512 MB Nix download buffer.**
- **Remove Tor, Snowflake, Ollama, Docker, Podman, thermald, Dropbox** unless a
  concrete use is found.
- **Do not delete `hyprland_hy3.nix`.** It is the fallback when hy3 breaks.
- **Neovim is the next work target**, with AI integration a main objective
  (2026-11-09). Keep the existing Nix-managed editor; see `nvim.md` for staged
  implementation and verification. This does not approve unrelated changes.
- **Keep all Treesitter grammars.** Neovim uses Nix-managed parsers; do not
  reintroduce runtime parser installation or reduce grammars as cosmetic cleanup.
- **Graphify uses one curated workflow** for code and research, including a
  verbatim TeX/text adapter. Integration is implemented; project scope, semantic
  backend/spending, and graph quality need explicit acceptance (`graphify.md`).

## Files

| File | Scope | Priority |
|---|---|---|
| [`security.md`](security.md) | secrets, SSH, lock screen, boot loader, groups, DNS | P0 |
| [`opencode.md`](opencode.md) | permissions, overnight runs, sandboxing, auth | P0/P1 |
| [`powersaving.md`](powersaving.md) | PPD, zram/swap, hibernate, idle, thermal | P1 |
| [`tor.md`](tor.md) | remove or correctly configure Tor; module placement | P1 |
| [`desktop-hyprland.md`](desktop-hyprland.md) | Hyprland vs alternatives, hy3, wofi, screenshots, plumbing, Waybar | P1/P2 |
| [`wallpapers.md`](wallpapers.md) | clean rotation, multi-monitor, state, tests | P2 |
| [`shell.md`](shell.md) | zsh/Starship/`nix develop`, AI, completions, aliases | P1/P2 |
| [`nvim.md`](nvim.md) | foundation/snippets/manual formatting implemented; editor AI and cleanup next | P1 |
| [`graphify.md`](graphify.md) | installed OpenCode integration, TeX/text adapter, semantic extraction pilot and acceptance | P1 |
| [`fonts.md`](fonts.md) | duplicate fonts, CJK choice, fallbacks | P1 |
| [`packages.md`](packages.md) | system/home split, removals, replacements, kernel/NTFS | P1 |
| [`backup.md`](backup.md) | restic/rustic design, destinations, restore drills | P0 |
| [`maintenance.md`](maintenance.md) | smartd, locate, journald, checks, README, reliability | P1 |
| [`maintainability.md`](maintainability.md) | repository hygiene, ownership, tests and bleeding-edge upgrade policy | P1/P2 |
| [`tools.md`](tools.md) | CLI tools and phased AI/research tooling rollout | P1/P2 |

These 15 topic files plus this index make up the 16 files in `docs/todos/`.

## Latest progress (2026-11-09)

- Neovim: namespaced store-backed Lua, one Treesitter setup with all grammars,
  editor-scoped tool dependencies, explicit LuaSnip and 33 Python/C++/LaTeX
  snippets, removal of old copies, and safe manual formatter commands.
- Verification: candidate builds and isolated editor/formatter/snippet checks
  passed during implementation. User reported `:ClangFormat` works; remaining
  interactive LSP/snippet/VimTeX/scnvim checks are not silently marked complete.
- Graphify: Home Manager CLI/helper, one allowlisted OpenCode skill/command,
  allowlisted UTF-8/TeX preparation with source mapping/hashes, output exclusions,
  and five passing helper tests. Optional DeepSeek flake package added in source;
  representative semantic extraction and measured savings remain open.
- No editor agent UI, Minuet completions, MCP service, automatic indexing, or
  format-on-save was enabled by these changes.

## Recommended order

**Current next batch:** finish Neovim cleanup/language support, then editor AI
integration (`nvim.md`). Run a scoped Graphify research pilot (`graphify.md`)
alongside that work before adding more retrieval systems (`tools.md`). Apply
`maintainability.md` throughout, without
turning editor work into a whole-repo rewrite. The risk-priority list remains useful,
but does not override this chosen work order. Key rotation and backups remain
unresolved security/data-loss priorities; they are not marked complete.

1. **Stop the bleeding:** rotate keys, `chmod 600`, remove global key export,
   harden SSH, remove `docker` group, add lock/idle.
2. **Remove dead weight:** Tor/Snowflake/Ollama/Docker/Podman/Dropbox/thermald,
   dead configs, duplicate packages, electron allowance.
3. **Correctness:** swap/hibernate, swappiness, `resolved`, `starship`,
   `mimeapps`, Sway output (only when tested), wallpaper scripts.
4. **Packages and system/home split:** one owner per package, move dev
   toolchains to devShells.
5. **Comfort:** `nh`, screenshots, Waybar modules, shell AI/completions,
   launcher, wallpaper refactor.
6. **Durability:** backups, smartd, locate, journald cap, checks, README.
7. **Deferred:** any compositor migration trial.

## Open decisions

- Backup destination: external USB HDD + Backblaze B2, or another provider?
- Is Peerflix/ezflix still used? If yes, keep it isolated; if no, remove.
- Do you want to trial Niri, or stay on Hyprland and simplify the config?
- Fuzzel (simple/stable) or Walker (Rust/plugin-rich) as the launcher?
- Should CUPS/Avahi stay if there is no printer?
- Pick a date to rotate the DeepSeek and Aliyun keys.

## Verification baseline

Useful before/after checks (run from the repo):

```sh
nix-instantiate --parse flake.nix
nix flake check --no-build
sudo nixos-rebuild build --flake .#NixSama
systemctl --failed
systemctl --user --failed
journalctl -p err -b --no-pager | tail -50
```

A full `nix eval` of the toplevel previously timed out while unpacking
nixpkgs; use `nixos-rebuild build` or `nh os build` for a decisive check.
