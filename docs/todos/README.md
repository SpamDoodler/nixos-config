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
- **Do not implement Nvim recommendations yet.** They are deferred to
  `nvim.md`.

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
| [`nvim.md`](nvim.md) | deferred Neovim redesign | P2 |
| [`fonts.md`](fonts.md) | duplicate fonts, CJK choice, fallbacks | P1 |
| [`packages.md`](packages.md) | system/home split, removals, replacements, kernel/NTFS | P1 |
| [`backup.md`](backup.md) | restic/rustic design, destinations, restore drills | P0 |
| [`maintenance.md`](maintenance.md) | smartd, locate, journald, checks, README, reliability | P1 |
| [`tools.md`](tools.md) | nh, atuin, tealdeer, dust, sd, xh, hyperfine, jless, just, typos, uv, plocate | P2 |

These 13 topic files plus this index make up the 14 files in `docs/todos/`.

## Recommended order

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
7. **Deferred:** Neovim redesign and any compositor migration trial.

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