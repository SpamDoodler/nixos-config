# Security

Priority: **P0**. The two largest risks are the unencrypted disk (accepted for
now) and secrets that are readable by every local process.

## Decisions

- No LUKS/FDE at the moment. Recovery after hardware failure matters more than
  at-rest encryption. This is a deliberate risk acceptance, not a fix.
- A lock screen is required. Use Hyprlock + Hypridle for Hyprland; add
  Swaylock/Swayidle only when the Sway session is next tested.
- Rotate the DeepSeek and Aliyun API keys. Assume the current files have been
  readable.
- Do not export `DEEPSEEK_API_KEY` globally. Only OpenCode needs it.

## 1. API keys and secrets (P0)

### Current state

- `home/shell.nix:22` exports `DEEPSEEK_API_KEY` in every interactive shell.
  Every child process (Chrome, Zoom, games, agents) inherits it.
- `~/.deepseek_key` is mode `0644`.
- `~/.config/opencode/opencode.json` is a real local file, mode `0644`, and
  contains the Aliyun key.
- `~/.config/opencode/opencode.jsonc` is a Home Manager symlink into
  `/nix/store`, which is world-readable. **Never put secrets in it.**
- `~/.local/share/opencode/auth.json` is mode `0600`. This is the correct
  place for provider credentials.

### Target design

1. Rotate both keys at the provider.
2. Store provider keys with `opencode auth login` (or `/connect` inside
   OpenCode). They land in `~/.local/share/opencode/auth.json` (0600).
3. Remove API keys from `~/.config/opencode/opencode.json`. Keep that file for
   non-secret local overrides only, mode `0600`.
4. If a key must stay in JSON, use OpenCode's file interpolation instead of an
   inline literal, for example
   `"apiKey": "{file:~/.secrets/deepseek-key}"`, with the secret file mode
   `0600` and outside the Nix store. Verify the exact syntax with
   `opencode debug config` after the change.
5. Delete `~/.deepseek_key` after migration. If it must stay temporarily:
   `chmod 600 ~/.deepseek_key` and stop sourcing it from `.zshrc`.
6. Do not manage secret files with `home.file`/`xdg.configFile`; Home Manager
   copies them into the world-readable Nix store.

### Why not just put the DeepSeek key in `opencode.json`?

It works, but it is the second-best option: the file is easy to copy, easy to
commit by accident, and readable by anything running as your user. `auth.json`
has the same trust boundary but a narrower purpose and already has the correct
mode. If you prefer one file, a 0600 `opencode.json` with `{file:...}` is
acceptable. Never inline it in `opencode.jsonc`.

### Residual risk without FDE

A physically present attacker can read the disk, including `auth.json`, browser
profiles, shell history, and SSH keys. Mitigations: BIOS/UEFI password, lock
screen on idle/suspend, encrypted backups, no secrets in the Nix store, rotate
keys if the laptop is lost, and keep the SSH agent from forwarding.

### Tasks

- [ ] Rotate DeepSeek key; update OpenCode auth.
- [ ] Rotate Aliyun key; update OpenCode auth.
- [ ] Remove key export from `home/shell.nix`.
- [ ] Move/remove `~/.deepseek_key`; set `0600` if retained.
- [ ] Set `~/.config/opencode/opencode.json` to `0600`; remove inline keys.
- [ ] Confirm `opencode auth list` shows the expected providers.
- [ ] Add a short secret-handling section to the root `README.md`.

### Verification

```sh
stat -c '%a %U:%G %n' ~/.deepseek_key ~/.config/opencode/opencode.json \
  ~/.local/share/opencode/auth.json
opencode auth list
opencode debug config | jq -r '.model, ((.provider // .providers // {})|keys)'
# The last command must not print key values.
```

## 2. SSH (P1)

### Current state

- `system/services.nix:85-87` enables sshd with defaults.
- `/etc/ssh/sshd_config` has `PasswordAuthentication yes` and
  `KbdInteractiveAuthentication yes`.
- `system/networking.nix:28` opens TCP 22.
- `PermitRootLogin prohibit-password`.
- `~/.ssh` uses RSA keys (`home/github.nix:17,30`); no agent forwarding policy.

### Target

1. Install an ed25519 public key in
   `users.users.spamdoodler.openssh.authorizedKeys.keys` **first**.
2. Only then disable passwords:

```nix
services.openssh.settings = {
  PasswordAuthentication = false;
  KbdInteractiveAuthentication = false;
  PermitRootLogin = "no";
  AllowUsers = ["spamdoodler"];
  X11Forwarding = false;
  AllowAgentForwarding = false;
  AllowTcpForwarding = "no";   # unless you need tunnels
  MaxAuthTries = 3;
  LoginGraceTime = 30;
};
```

3. Remove `22` from `networking.firewall.allowedTCPPorts`. If remote access is
   needed, put SSH behind WireGuard/Tailscale instead of exposing it.
4. If SSH must stay public, enable `services.fail2ban` (or sshguard) and keep
   key-only auth.
5. Migrate Git keys to ed25519 and let `ssh-agent` select them; remove
   `core.sshCommand = "ssh -i ..."` unless a specific key is required. Consider
   SSH signing instead of `signing.format = null`.

### Tasks

- [ ] Add ed25519 public key to NixOS config.
- [ ] Disable password and keyboard-interactive auth.
- [ ] Remove port 22 from the firewall (or scope it).
- [ ] Test from a second machine **before** closing the current session.
- [ ] Migrate RSA Git keys to ed25519; configure `ssh-agent`.
- [ ] Add `fail2ban` only if SSH remains exposed.

### Verification

```sh
sshd -T | grep -E '^(passwordauthentication|kbdinteractiveauthentication|permitrootlogin|allowusers)'
ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no user@host
# The second command must fail.
```

## 3. Lock, idle, notifications, polkit, keyring (P0/P1)

### Why

There is currently no lock screen, idle daemon, notification daemon, polkit
agent, keyring, or clipboard manager. GUI authentication prompts and
notifications can silently fail, and walking away leaves the session open.

### Suggested Home Manager configuration

```nix
# Verify each option against the pinned Home Manager revision before merging.
programs.hyprlock.enable = true;
services.hypridle.enable = true;
services.hyprpolkitagent.enable = true;
services.mako.enable = true;          # or services.swaync.enable
services.cliphist.enable = true;
programs.waybar.systemd.enable = true;
```

NixOS side:

```nix
services.gnome.gnome-keyring.enable = true;
security.pam.services.login.enableGnomeKeyring = true;
services.udisks2.enable = true;
services.gvfs.enable = true;
```

Hypridle policy (start conservative):

```nix
services.hypridle.settings = {
  general = {
    lock_cmd = "pidof hyprlock || hyprlock";
    before_sleep_cmd = "loginctl lock-session";
    after_sleep_cmd = "hyprctl dispatch dpms on";
  };
  listener = [
    { timeout = 300;  on-timeout = "hyprctl dispatch dpms off"; on-resume = "hyprctl dispatch dpms on"; }
    { timeout = 600;  on-timeout = "loginctl lock-session"; }
    { timeout = 900;  on-timeout = "systemctl suspend"; }
  ];
};
```

Add a `SUPER + L` binding to `loginctl lock-session`. Add `swaylock` +
`swayidle` only for the Sway fallback, and test Sway separately.

Clipboard history is a privacy risk. Wipe it on lock if you use cliphist:
`cliphist wipe` in `lock_cmd`, or keep history disabled.

### Tasks

- [ ] Install and configure Hyprlock + Hypridle.
- [ ] Add `SUPER + L` lock binding.
- [ ] Add polkit agent.
- [ ] Add notification daemon and test `notify-send`.
- [ ] Add keyring and unlock it at login.
- [ ] Decide on clipboard history; if enabled, wipe on lock.
- [ ] Add `NIXOS_OZONE_WL=1` for Electron/Wayland apps.

## 4. Groups and virtualisation (P1)

`users/users.nix:12-14` puts the user in `libvirtd`, `podman`, and `docker`.
The `docker` group is effectively root: anyone in it can mount the host
filesystem through the daemon. Rootless Docker is already enabled, so the group
is unnecessary.

- Remove `docker`, `podman`, and `libvirtd` from `extraGroups` unless a concrete
  use remains.
- Remove `virtualisation.docker` and `virtualisation.podman` if no containers
  are used. See [`packages.md`](packages.md) for the Podman explanation.
- If libvirt is kept for VMs, set `virtualisation.libvirtd.onBoot = "socket"`
  (or `"manual"`) so it does not run at boot.

## 5. Boot loader (P1)

### Current

`system/boot.nix:21-22` enables systemd-boot with the default editor enabled.
Anyone with physical access can add `init=/bin/sh` and get a root shell, even
without disk encryption.

### Proposed

```nix
boot.loader.systemd-boot.editor = false;
boot.loader.systemd-boot.configurationLimit = 5;  # /boot is small
boot.loader.timeout = 3;
```

### Downside (answer)

`editor = false` also removes your ability to edit kernel parameters at boot.
That makes recovery from a bad `resume=`, `amd_pstate=`, or display parameter
harder: you must boot an older generation or a live USB instead. Mitigations:

- keep at least 3–5 known-good generations (`configurationLimit = 5`);
- keep a rescue USB with a NixOS ISO;
- test kernel/initrd changes with `nixos-rebuild boot` and a reboot, not
  `switch`;
- document the recovery procedure in the root `README.md`.

`configurationLimit` prunes old entries. With only ~278 MiB free on `/boot`,
5 is a reasonable start; do not set it to 1.

### Tasks

- [ ] Set `editor = false`.
- [ ] Set `configurationLimit = 5`.
- [ ] Add memtest86 if there is room (optional).
- [ ] Write the recovery section in `README.md`.
- [ ] Keep a rescue USB.

## 6. DNS and Wi-Fi privacy (P2)

`system/networking.nix:22` forces `9.9.9.9` in plaintext and bypasses
NetworkManager DNS. `system/services.nix:116-124` configures systemd-resolved
with DNSSEC/DoT but disables it. `wifi.scanRandMacAddress = false` disables MAC
randomization.

Target:

```nix
services.resolved.enable = true;
networking.networkmanager.dns = "systemd-resolved";
# remove networking.nameservers
networking.networkmanager.wifi.scanRandMacAddress = true;
```

Keep `wifi.powersave = false` only if the RTL8852BE is unstable without it;
otherwise test `true` for battery life (see [`powersaving.md`](powersaving.md)).
MAC randomization can break captive portals; toggle it if a hotel/airport
network refuses to cooperate.

### Tasks

- [ ] Enable resolved, switch NetworkManager to it, remove `nameservers`.
- [ ] Test DNS, DNSSEC, and captive portals.
- [ ] Enable MAC randomization; document the captive-portal workaround.
- [ ] Test Wi-Fi powersave separately.

## 7. Additional hardening (P2)

- [ ] `boot.kernel.sysctl."kernel.kptr_restrict" = 2;`
- [ ] `boot.kernel.sysctl."kernel.dmesg_restrict" = 1;`
- [ ] `boot.kernel.sysctl."kernel.yama.ptrace_scope" = 1;` (Yama is already in
      `lsm=`).
- [ ] `boot.kernel.sysctl."net.ipv4.tcp_syncookies" = 1;`
- [ ] BIOS/UEFI password; disable boot from external media only if recovery is
      understood.
- [ ] Consider `usbguard` only if you routinely plug in untrusted devices.
- [ ] Do not install `fail2ban` as a substitute for key-only SSH.

## Open questions

- Do you need inbound SSH at all, or is it only for LAN/GitHub?
- Is a printer actually used? If not, CUPS + Avahi can be removed (see
  `packages.md`).
- Do you want a keyring, or do you prefer browser-managed passwords?
- Should the lock screen also trigger on lid close and suspend? (Recommended.)