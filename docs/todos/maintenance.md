# Maintenance and reliability

Priority: **P1**. Small, boring changes that prevent a full disk, a lost
generation, or a silent service failure.

## Current state

| Item | Current | File |
|---|---|---|
| `smartd` | not enabled | — |
| `locate` | not enabled | — |
| journald | persistent, rate-limited, **no size cap** | `system/services.nix:30-34` |
| Nix GC | weekly, delete older than 30d | `system/nix.nix:9-13` |
| Nix daemon | `max-jobs = 8`, no `cores` | `system/nix.nix:14-23` |
| systemd-boot | default editor, no generation limit | `system/boot.nix:21-22` |
| fstrim / fwupd | weekly / enabled | `system/services.nix:93-97` |
| formatting | `alejandra` | `flake.nix:43` |
| flake checks | none | `flake.nix` |
| root README | none | — |
| `nh` | not installed | — |
| `.gitignore` | only `.opencode-tmp/` | `.gitignore` |
| `flake.lock` | modified, uncommitted | Git |

## 1. SMART and `locate`

```nix
services.smartd.enable = true;

services.locate = {
  enable = true;
  package = pkgs.plocate;
  prunePaths = [
    "/nix/store" "/tmp" "/var/tmp"
    "/home/spamdoodler/.cache"
    "/home/spamdoodler/.local/share/Steam"
    "/home/spamdoodler/.opencode-tmp"
  ];
};
```

`smartd` logs to the journal; there is no mail transport here, so either read
it or add a notifier later. Check the NVMe:

```sh
sudo smartctl -a /dev/nvme0n1
sudo nvme smart-log /dev/nvme0n1
```

For `locate`, run `sudo updatedb` once, then `locate flake.nix`. Pruning
`/nix/store` keeps the database small. Use `fd` inside a project and `rg` for
content; `locate` is for “where is that file on the whole system?”.

- [ ] Enable `smartd`.
- [ ] Enable `locate` with `plocate`; prune caches/store.
- [ ] Record the drive model/serial and SMART warning path.

## 2. journald cap: 1 GiB

```nix
services.journald.settings.Journal = {
  Storage = "persistent";
  SystemMaxUse = "1G";
  SystemMaxFileSize = "100M";
  MaxRetentionSec = "1month";
  RateLimitInterval = "30s";
  RateLimitBurst = 1000;
};
```

After switching, run `journalctl --vacuum-size=1G` if the existing journal is
larger. Verify with `journalctl --disk-usage`.

- [ ] Add the cap and retention.
- [ ] Vacuum the existing journal.
- [ ] Confirm the size stays bounded after a week.

## 3. Nix GC and generations

Add a systemd-boot generation limit (the `/boot` partition is small):

```nix
boot.loader.systemd-boot.configurationLimit = 5;
boot.loader.timeout = 3;
```

Keep 3–5 known-good generations. Do not set it to 1; a bad kernel or Hyprland
update needs a fallback. Test kernel/initrd changes with
`nixos-rebuild boot` + reboot, not `switch`.

```sh
nix-env --list-generations --profile /nix/var/nix/profiles/system
sudo nix-collect-garbage --delete-older-than 14d
nix store gc --dry-run
df -h / /boot
```

Do not run `nix-collect-garbage -d` casually: it removes all old generations,
including the fallback. Prefer age-based GC or `nh clean`.

- [ ] Set `configurationLimit = 5`.
- [ ] Set a boot timeout.
- [ ] Keep a rescue USB.
- [ ] Test one `boot` + reboot cycle.

## 4. Formatting and checks

The flake uses `formatter.${system} = pkgs.alejandra`. Pick one formatter:

- **Alejandra** — current, fast, opinionated.
- **`nixfmt-rfc-style`** — official RFC 166 style, also fine.

Do not mix. Add a check (full snippet in [`packages.md`](packages.md)):

```nix
checks.${system}.formatting = pkgs.runCommand "check-formatting" {
  nativeBuildInputs = [pkgs.alejandra];
} ''
  alejandra --check ${self}
  touch $out
'';
```

```sh
nix flake check --no-build
nix build .#checks.x86_64-linux.formatting --no-link
alejandra --check .
```

Optional: `statix` (Nix antipatterns), `deadnix` (unused bindings), `typos`
(spelling), and `pre-commit` hooks. Do not add a hook that rewrites files on
every commit unless you actually run it.

- [ ] Choose Alejandra or nixfmt-rfc-style.
- [ ] Add `checks.${system}`.
- [ ] Run `nix flake check --no-build`.
- [ ] Add linters/hooks only if they find real issues.

## 5. Root `README.md`

There is no root README. Create one with:

```markdown
# NixSama

HP 255 G10, AMD Ryzen 5 7530U, 14 GiB RAM, AMD iGPU, RTL8852BE Wi-Fi.
NixOS unstable + Home Manager + Hyprland (Sway fallback).

## Rebuild
    sudo nixos-rebuild switch --flake .#NixSama
    nh os switch
    nix flake check --no-build

## Rollback
- Boot menu: older generation.
- sudo nixos-rebuild switch --rollback
- nix-env --list-generations --profile /nix/var/nix/profiles/system

## Structure
system/  NixOS modules
home/    Home Manager modules
hardware/ machine config
fonts/   font packages
scripts/ wallpaper/waybar helpers
docs/todos/ audit and plans

## Desktop
- TTY1 + start-hyprland.
- Fallback: import hyprland_hy3.nix instead of hyprland_hy_lua.nix.
- Do not import both.
- Waybar: SUPER+X; wallpaper: SUPER+SHIFT+B.
- Screenshots: ~/Pictures/Screenshots (after binding is added).

## Secrets
- Keys in ~/.local/share/opencode/auth.json (0600) or a 0600 file.
- Never inline keys in opencode.jsonc (Nix store).
- No FDE: lock screen, BIOS password, encrypted backups.

## Recovery
- Keep a NixOS live USB.
- Restore with restic; rebuild from the restored flake.
- systemd-boot editor: consider disabling (see `security.md`); use an older
  generation or live USB for recovery.

## Hardware notes
- USB-C has no DP Alt Mode; HDMI is the only external output.
- linux_testing is intentional.
- patches.nix is an unimported escape hatch.
```

Omit anything that becomes stale; link to this directory for details.

- [ ] Create root `README.md`.
- [ ] Document fallback, recovery, screenshots, backup.
- [ ] Keep secrets out of it.

## 6. `nh`

```nix
home.packages = [pkgs.nh];
```

```sh
nh os switch
nh os boot
nh os test
nh home switch
nh clean all --keep 5
nh search ripgrep
```

`nh` is a convenience, not a replacement for understanding
`nixos-rebuild`. Keep the plain commands in the README as the fallback.

- [ ] Install `nh`.
- [ ] Add `nrs`/`nrb`/`nrt` aliases (see [`shell.md`](shell.md)).
- [ ] Confirm the host is `.#NixSama`.

## 7. Reliability checklist

After a significant rebuild:

```sh
systemctl --failed --no-legend
systemctl --user --failed --no-legend
journalctl -p err -b --no-pager | tail -50
hyprctl configerrors
fc-match monospace
```

Weekly/monthly:

```sh
journalctl --disk-usage
df -h / /boot
sudo smartctl -a /dev/nvme0n1 | grep -E 'Percentage Used|Media|Available Spare'
sudo fwupdmgr get-updates
nix store gc --dry-run
restic snapshots
```

Desktop: `hyprctl reload` + `hyprctl configerrors`; keep `hyprland_hy3.nix`
as fallback; pin Hyprland and `hyprlandPlugins.hy3` to the same nixpkgs; do
not delete the previous generation until the new session starts;
`fc-cache -fv` after font changes.

## 8. Boot and kernel hygiene

- **Keep `linux_testing`.** Intentional.
- **Remove `systemd.unified_cgroup_hierarchy=1`** from
  `system/boot.nix:17`; unified cgroups are the default on systemd 262.
  Verify with `systemctl --version` and `mount | grep cgroup2`.
- Keep `amd_pstate=guided` unless measurements disagree.
- Keep the NVIDIA blacklist; it does not affect NTFS or AMD graphics.
- Do not add `resume=` manually if `boot.resumeDevice` is set (see
  [`powersaving.md`](powersaving.md)).
- `systemd-boot.editor = false` is a security tradeoff; keep a rescue USB
  and older generations (see [`security.md`](security.md)).

## 9. Git hygiene

Add to `.gitignore`:

```gitignore
/.opencode-tmp/
/result
/result-*
*.qcow2
*.iso
.direnv/
```

`flake.lock` is modified; review and commit it with the change that requires
it. Commit formatting separately from behavior changes. Never commit secrets,
`auth.json`, `opencode.json` with keys, or backup credentials.

## Tasks

- [ ] Enable `smartd`.
- [ ] Enable `locate` with `plocate`.
- [ ] Cap journald at 1 GiB.
- [ ] Set `configurationLimit = 5` and a boot timeout.
- [ ] Add flake `checks` and one formatter.
- [ ] Create root `README.md`.
- [ ] Install `nh`.
- [ ] Remove `systemd.unified_cgroup_hierarchy=1`.
- [ ] Update `.gitignore`; commit `flake.lock`.
- [ ] Run the reliability checklist.
- [ ] Test and document the Hyprland and Sway fallbacks.
- [ ] Schedule a restore drill.

## Open questions

- SMART warnings: journal, desktop notification, or email?
- `nh` system-wide or Home Manager only?
- Alejandra or `nixfmt-rfc-style` long-term?
- How many generations fit in `/boot` comfortably?
- Should the README be public (it contains host details)?