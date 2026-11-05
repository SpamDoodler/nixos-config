# Packages and system/home split

Priority: **P1**. The package set has one obvious duplicate, several packages
in the wrong layer, a few dead or obsolete tools, and a broad insecure-package
allowance. This file is the cleanup plan; it does not remove anything by
itself.

## Current split

### System (`system/programs.nix`)

```text
unzip p7zip eza starship ripgrep git fd fmt git-lfs jq delta
grim alacritty kitty bottom powertop neovim zathura wget curl
fastfetch pamixer paprefs pavucontrol pciutils iw linux-firmware nmap rsync
ffmpeg-full lm_sensors feh gcc cmake cxxopts pkg-config fzf libinput
trash-cli alsa-utils gparted gphoto2 gphoto2fs libtiff ncdu bat
openconnect openssl graphviz zgrviewer ghostscript smartmontools
wl-clipboard zip imagemagick uutils-procps psmisc tmux
```

`environment.variables.EDITOR = "nvim"` is also set here.

### Home (`home/packages.nix`)

```text
swaybg oh-my-zsh dosbox-staging google-chrome texliveFull mpv ani-cli
peerflix-server osu-lazer-bin inkscape rawtherapee libreoffice-qt hunspell
hunspellDicts.en-us tor-browser tdf gap-full supercollider lilypond lie
rainloop-standard pre-commit signal-desktop ueberzugpp imagemagick zoom-us
```

`programs.firefox` is enabled here. Other Home Manager modules install
`ghostty`, `alacritty`, `bat`, `neovim`, `zsh`, `starship`, `zoxide`,
`direnv`, `waybar`, `hyprland`, `sway`, `yazi`, and the shell tooling.

## Policy

| Layer | Belongs there | Examples |
|---|---|---|
| NixOS | Boot, kernel, firmware, services, drivers, system-wide CLI needed before login, security tools | `linux_testing`, `amdgpu`, `smartmontools`, `git`, `curl`, `rsync`, `zsh` |
| Home Manager | User applications and their configs, desktop session, per-user services | Chrome, Firefox, Ghostty, Neovim, Waybar, Hyprland, `texliveFull` |
| devShell | Project compilers, libraries, language servers, formatters | `gcc`, `cmake`, `pkg-config`, `cxxopts`, `fmt`, `libtiff`, Python/Node toolchains |
| Never both | One owner per package | `imagemagick`, `bat`, `alacritty`, `neovim`, `starship`, `oh-my-zsh`, `linux-firmware` |

Rule of thumb: if a system service or the login path needs it, put it in
NixOS. If you launch it as a user, put it in Home Manager. If it is only
needed to build a project, put it in that project's devShell.

## Duplicates and wrong-layer packages

| Package | Problem | Action |
|---|---|---|
| `imagemagick` | In both `home/packages.nix` and `system/programs.nix` | Keep system (CLI); remove Home copy |
| `bat` | System package + `programs.bat.enable` | Keep HM module; remove system package |
| `alacritty` | System package + `programs.alacritty.enable` | Keep HM; remove system (or remove both if unused) |
| `neovim` | System package + `programs.neovim.enable` | Keep HM; remove system |
| `starship` | System package + `programs.starship.enable` | Keep HM; remove system |
| `oh-my-zsh` | `home/packages.nix:8` + `programs.zsh.oh-my-zsh` | Remove the package line |
| `linux-firmware` | Explicit + `hardware.enableRedistributableFirmware` | Remove explicit; the firmware option owns it |
| `swaybg` | Home package; only needed by Sway | Keep for the Sway fallback, or move to the Sway module |
| `pamixer` | System package; used by `sway.conf` | Keep until Sway is tested or switch Sway to `wpctl` |
| `gcc`, `cmake`, `pkg-config` | System compilers used only for development | Move to devShells |
| `cxxopts`, `fmt`, `libtiff` | C/C++ libraries, not CLI tools | Move to the relevant devShell |
| `paprefs` | PulseAudio preferences GUI; PipeWire ignores most of it | Remove |
| `uutils-procps` | Rust replacement for `procps` (`ps`, `top`, `kill`) | Remove unless you specifically want it |
| `feh` | X11 image viewer/wallpaper setter | Remove; use `imv` and `hyprpaper` |
| `zgrviewer` | Java Graphviz viewer, obsolete | Remove; use `dot -Tsvg` + `imv`/browser, or `zathura` for PDF |
| `gphoto2fs` | FUSE mount for a camera | Remove if no camera; keep `gphoto2` if you use one |
| `rainloop-standard` | PHP webmail application | Remove unless you host webmail |
| `peerflix-server` | Old Node streaming-torrent web UI | Remove unless actively used; see below |
| `tor-browser` | Browser; only useful if you use Tor Browser | Remove if Tor is being dropped; it bundles its own Tor and does not need the system daemon |
| `corefonts` | Proprietary compatibility fonts | Keep only if a document/app needs Arial/Times |
| `lmodern`, `lmmath` | TeX fonts; `texliveFull` already has them | Keep only if non-TeX apps need them through fontconfig |

## Package-by-package answers

### `rainloop-standard`

RainLoop is a PHP webmail client: a web application you run behind a web
server, not a desktop mail client. Nothing in this configuration integrates
it with a browser, a mail account, or a service. It is dead weight. Remove it;
use your mail provider's web UI or a mail client (Thunderbird/Evolution) if
you need one.

### `peerflix-server`, `ezflix`, and streaming

`peerflix-server` is a Node.js web UI around torrent streaming. It is old,
unmaintained, exposes a local HTTP service, and has no sandbox. `ezflix` and
the original `peerflix` are not packaged in the pinned nixpkgs, so there is no
supported drop-in.

Options:

- **qBittorrent** (packaged, actively maintained) for a full BitTorrent
  client; stream completed files with `mpv`.
- **`ani-cli`** for anime; it already uses `mpv` and is in Home packages.
- Keep `peerflix-server` only if you actively use its web UI, and isolate it
  (separate user/container, firewall it to localhost). Do not expose it on the
  LAN.
- Do not add an unmaintained “streaming” wrapper just to avoid downloading.

Legal and security note: torrent streaming is not inherently illegal, but the
sources and content are your responsibility. An unmaintained web service is a
poor trade for convenience.

### `zgrviewer`

ZGRViewer is a Java Swing Graphviz graph viewer. It is obsolete for this use:
`dot -Tsvg graph.dot -o graph.svg` plus `imv graph.svg` (or a browser) is
faster, and `dot -Tpdf` plus `zathura` is better for print. Remove
`zgrviewer`; keep `graphviz` for the `dot` CLI.

### `uutils-procps`

A Rust reimplementation of `procps` (`ps`, `top`, `kill`, `free`, etc.). It
can shadow the GNU tools and change flag behaviour in scripts. There is no
workflow here that needs it. Remove it; the standard `procps` from NixOS is
already present.

### `paprefs`

A PulseAudio preferences GUI. PipeWire's PulseAudio compatibility layer does
not implement most of these settings, so the GUI is misleading. Remove it.
Use `pavucontrol` for routing and `wpctl` for scripts.

### `feh` replacement

`feh` is X11-only and cannot set a Hyprland wallpaper. It is not needed for a
Wayland-only session.

- **Viewing images:** `imv` — Wayland-native, keyboard-driven, tiling-friendly.
- **Wallpaper:** `hyprpaper` (see [`wallpapers.md`](wallpapers.md)).
- **Quick alias:** if you have muscle memory, add
  `shellAliases.feh = "imv"`. Make clear that `feh --bg-fill` will not work;
  use `hyprctl hyprpaper wallpaper`.
- **Alternative:** `loupe` (GNOME, GTK4) or `qimgv` (Qt) if you want a
  browser-like viewer. `imv` is the smallest good fit here.

### `tdf`, `lie`, `ueberzugpp`, `ani-cli`, `pamixer`

- **`tdf`** — a TUI PDF viewer. Keep if you read PDFs over SSH/without a GUI;
  otherwise `zathura` is the better desktop viewer.
- **`lie`** — a computer-algebra package for Lie group computations. Keep if
  your mathematics work uses it; it is not a general utility.
- **`ueberzugpp`** — draws images in terminals for file managers/previews.
  Yazi may use its own previewer; if you do not use a terminal file manager
  that needs it, remove it.
- **`ani-cli`** — CLI anime browser/player built around `mpv`. Keep if used;
  remove if not.
- **`pamixer`** — PulseAudio CLI mixer used by the Sway config. Keep for the
  Sway fallback, or migrate Sway to `wpctl` when Sway is tested.

### Terminals

There are three terminal emulators: Ghostty (Home Manager, default),
Kitty (system, no config), Alacritty (system + Home Manager config).

- All three are lightweight when closed; having them installed costs disk, not
  RAM. Running several at once is fine on 14 GiB.
- **Ghostty** is the default (`SUPER + RETURN`) and is the most actively
  developed of the three. Keep.
- **Kitty** is mature, fast, supports images/ligatures/splits, and is a good
  fallback. Keep.
- **Alacritty** is still maintained, but it is deliberately minimal and lacks
  some features. It is not “outdated” in the abandoned sense, but it adds a
  third config for little benefit. Remove it unless you need its specific
  GPU/performance behaviour; if you remove it, also remove
  `home/alacritty.nix` from the imports and the system package.

Recommendation: **Ghostty primary, Kitty fallback, drop Alacritty** unless a
specific workflow needs it.

### Browsers

- **Google Chrome** — DRM video, Google services, sites that require
  Chromium-specific features.
- **Firefox** — default privacy-oriented browsing, container tabs, extensions.
- **Tor Browser** — anonymity; it bundles its own Tor and does not need
  `services.tor`. Keep only if you actually use it. If you remove Tor, this is
  the one Tor-related package that can stay independently.
- Multiple browsers do not consume resources when closed. Disk/update cost is
  the real price. Keeping Chrome + Firefox is reasonable; a third browser
  needs a purpose.

### `texliveFull` and `ffmpeg-full`

- Keep `texliveFull`: the user explicitly wants the full TeX Live set for
  LaTeX/vimtex. It is large, but it is a deliberate choice.
- Keep `ffmpeg-full`: SuperCollider, mpv, and media work benefit from the
  extra codecs/features. It is a system package; that is fine for a shared
  media tool.

## X11-free session

`services.xserver.enable = false` is already set. The practical target is:

- no X11 **session** or X11 window manager;
- Wayland-native apps where possible;
- XWayland only for things that still need it (Steam, some games, Java apps).

Remove `feh` and `zgrviewer` (X11/Java GUI). Keep XWayland enabled for Steam;
disabling it would break Steam and some games. “X11-free” should mean “no X11
desktop”, not “break XWayland compatibility”.

## NTFS, NVIDIA blacklist, and swappiness

### Does blacklisting NVIDIA modules hurt NTFS?

**No.** `ntfs3` is a filesystem driver; `nouveau`/`nvidia*` are GPU drivers.
They are unrelated. Blacklisting NVIDIA modules on this AMD-only laptop is
harmless and prevents a driver you do not use from loading.

For a drive you mount only sometimes, prefer an on-demand mount:

```nix
fileSystems."/mnt/windows" = {
  device = "/dev/disk/by-uuid/REPLACE-ME";
  fsType = "ntfs3";
  options = [
    "uid=1000"
    "gid=100"
    "umask=022"
    "nofail"
    "x-systemd.automount"
    "x-systemd.idle-timeout=600"
  ];
};
```

`nofail` prevents a boot failure when the drive is absent; `x-systemd.automount`
mounts it on first access. Keep `boot.supportedFilesystems = ["ntfs"]` so the
kernel module is available. If `ntfs3` refuses a dirty Windows volume, boot
Windows and shut it down cleanly (disable Fast Startup) or use `ntfs-3g` as a
fallback.

### Swappiness

`vm.swappiness = 10` is wrong for a zram-first laptop. Raise it to `100` (see
[`powersaving.md`](powersaving.md)); this is independent of NTFS.

## Virtualisation: Docker, Podman, libvirtd

Current state:

- `virtualisation.libvirtd.enable = true` and the user is in `libvirtd`.
- `virtualisation.docker.enable = true` with rootless Docker and
  `setSocketVariable = true`; the user is in `docker`.
- `virtualisation.podman.enable = true`; the user is in `podman`.
- `services.ollama.enable = true`.

### What Podman was for

Podman is a daemonless, rootless OCI container engine with a Docker-compatible
CLI. It can run the same images as Docker without a root daemon, and it is
often used for `distrobox`/toolbox-style development environments or for
running a single service without Docker's daemon. `dockerCompat = false` means
it does not install a `docker` alias/socket compatibility layer. Nothing in
this repo uses it; no containers, Compose files, or distrobox config exist.
Remove it, along with the `podman` group.

### What to keep

- Unless you use containers, remove **both** Docker and Podman, and remove the
  `docker`/`podman` groups. The `docker` group is effectively root; rootless
  Docker does not need it.
- If you keep libvirt for VMs, set it to socket activation:
  ```nix
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "socket";   # verify the allowed value in the pinned NixOS
  };
  ```
  `"manual"` is the stricter option if you want to start it yourself. Remove
  the `libvirtd` group only if you also remove libvirt.
- Remove `services.ollama`; no local models are configured, and it is a
  background service with a network listener.
- Tor/Snowflake: see [`tor.md`](tor.md).

## Nix daemon settings

`system/nix.nix` currently has `max-jobs = 8` on a 6-core/12-thread laptop.
The requested settings are:

```nix
nix.settings = {
  max-jobs = 4;
  cores = 3;
  download-buffer-size = 524288000;   # keep 512 MB
  auto-optimise-store = true;
  experimental-features = ["nix-command" "flakes"];
};
```

`max-jobs = 4` with `cores = 3` allows up to 12 concurrent compile jobs, which
matches the 12 threads. It is a reasonable balance; lower `max-jobs` to 2 if
the laptop thermally throttles or runs out of RAM. Keep the 512 MB download
buffer. `auto-optimise-store` is fine; `nix.optimise.automatic` is optional and
can be expensive, so do not enable it without measuring.

`nix.gc` is weekly with `--delete-older-than 30d`; that is reasonable. Add a
`min-free`/`max-free` policy only if the disk actually fills.

## Insecure Electron allowance

`system/nix.nix:26-28` permits `electron-24.8.6` globally. That is an old
Electron with known vulnerabilities. Steam does **not** need the nixpkgs
Electron package; it uses its own bundled runtime. Remove the allowance:

```nix
# nixpkgs.config.permittedInsecurePackages = [ "electron-24.8.6" ];
```

If a build later fails, add only the exact package and version it names, with
a comment explaining why and a plan to remove it. Never keep a blanket list
“just in case”.

## Flake `checks`

Add a checks output so `nix flake check` has something to evaluate:

```nix
checks.${system} = {
  nixos = self.nixosConfigurations.NixSama.config.system.build.toplevel;

  formatting = pkgs.runCommand "check-formatting" {
    nativeBuildInputs = [pkgs.alejandra];
  } ''
    alejandra --check ${self}
    touch $out
  '';
};
```

`nix flake check` will build the system toplevel, which is expensive. Use
`nix flake check --no-build` for a quick syntax/eval check, and let CI or a
manual run build the toplevel. The formatting check uses the same formatter as
`formatter.${system} = pkgs.alejandra`; if you switch to `nixfmt-rfc-style`,
update both and do not mix styles.

## XDG MIME defaults

`home/xdg.nix` currently maps only PDF and also forces two `mimeapps.list`
locations. `xdg.mimeApps` already writes the file; the extra `force` and
`xdg.dataFile` writes are redundant and can conflict. Replace with:

```nix
xdg.mimeApps = {
  enable = true;
  defaultApplications = {
    "application/pdf" = "org.pwmt.zathura.desktop";

    "text/plain" = "nvim.desktop";
    "text/markdown" = "nvim.desktop";

    "image/png" = "imv.desktop";
    "image/jpeg" = "imv.desktop";
    "image/gif" = "imv.desktop";
    "image/webp" = "imv.desktop";
    "image/svg+xml" = "imv.desktop";

    "video/mp4" = "mpv.desktop";
    "video/x-matroska" = "mpv.desktop";
    "audio/mpeg" = "mpv.desktop";
    "audio/flac" = "mpv.desktop";

    "text/html" = "google-chrome.desktop";
    "x-scheme-handler/http" = "google-chrome.desktop";
    "x-scheme-handler/https" = "google-chrome.desktop";
  };
};
```

Remove:

```nix
xdg.configFile."mimeapps.list".force = true;
xdg.dataFile."applications/mimeapps.list".force = true;
```

Verify the desktop file names after installing the packages:

```sh
ls /run/current-system/sw/share/applications | grep -E 'imv|mpv|nvim|chrome'
```

`nvim.desktop` runs a terminal editor; if `xdg-open` cannot find a terminal,
create a small desktop file that launches `ghostty -e nvim %F` instead. Test
`xdg-open` on a text file, an image, a video, and a URL.

## Other package changes

- **Steam firewall:** `programs.steam.remotePlay.openFirewall = true` and
  `dedicatedServer.openFirewall = true` open ports. Set both to `false` unless
  you use Remote Play or host a dedicated server.
- **Printing/Avahi:** `services.printing` and `services.avahi` are enabled and
  Avahi opens mDNS. If you have no printer, remove both; if you do, keep them
  and consider `openFirewall = false` on trusted networks. This is an open
  question.
- **`programs.firefox.configPath`:** it points at
  `~/.config/mozilla/firefox`, which is not the usual Firefox profile root.
  Verify it is intentional; if not, remove `configPath` and let Home Manager
  use the default. Do not change it in the same rebuild as a Firefox profile
  migration.
- **`gphoto2fs`/`gphoto2`:** keep only if you connect a camera.
- **`openconnect`:** VPN client; keep if used.
- **`nmap`:** security scanner; keep if used, but do not run it against
  networks you do not own.
- **`gparted`:** GUI partition editor; keep for rescue work.
- **`libinput`:** useful for `libinput debug-events`; keep if debugging input.
- **`powertop`, `bottom`, `ncdu`, `fastfetch`, `tmux`:** keep as diagnostics/
  terminal tools; see [`tools.md`](tools.md).

## Tasks

- [ ] Remove duplicate `imagemagick` from Home.
- [ ] Remove `bat`, `alacritty`, `neovim`, `starship` from system packages
      where Home Manager already owns them.
- [ ] Remove `oh-my-zsh` from `home/packages.nix`.
- [ ] Remove explicit `linux-firmware`.
- [ ] Remove `paprefs`, `uutils-procps`, `feh`, `zgrviewer`, `rainloop-standard`,
      `peerflix-server`.
- [ ] Add `imv` and, if wanted, `shellAliases.feh = "imv"`; keep `mpv` for
      video and `zathura` for PDF.
- [ ] Remove `tor-browser` if Tor Browser is not used.
- [ ] Remove `gphoto2fs` if no camera.
- [ ] Move `gcc`, `cmake`, `pkg-config`, `cxxopts`, `fmt`, `libtiff` to
      devShells.
- [ ] Decide on `corefonts`, `lmodern`, `lmmath`, `tdf`, `lie`, `ueberzugpp`,
      `ani-cli`, `pamixer`.
- [ ] Remove Docker, Podman, Ollama, and their groups; set libvirtd to socket
      activation if kept.
- [ ] Remove the `electron-24.8.6` insecure allowance.
- [ ] Set `max-jobs = 4`, `cores = 3`; keep the 512 MB buffer.
- [ ] Add `checks.${system}` and a formatting check.
- [ ] Replace `home/xdg.nix` with the MIME defaults above.
- [ ] Fix or remove Dropbox (see below).
- [ ] Disable Steam Remote Play/dedicated-server firewall openings unless used.
- [ ] Rebuild and compare `nix path-info -S`/closure size.

## Dropbox: repair or remove

`home/dropbox.nix` defines a user service that runs
`${pkgs.dropbox}/bin/dropbox` with `Restart=on-failure`. It has no
`DISPLAY`/Wayland environment, no tray integration, and no `EnvironmentFile`.
Dropbox's Linux client is also awkward on Wayland/Hyprland. Since it does not
work, **remove it** unless you need Dropbox sync specifically.

Options if you need Dropbox:

- **Maestral** — a maintained open-source Dropbox client with CLI and Qt GUI;
  better fit than the official daemon on Linux.
- **rclone** — sync a local directory to Dropbox on a systemd timer; no tray,
  no GUI, scriptable. Use `rclone config` once, store the config `0600`.
- Official `dropbox` daemon — keep only if you need its exact sync semantics,
  and run it under a proper session with a tray.

Remove the import from `home/spamdoodler.nix`, delete `home/dropbox.nix`, and
remove `dropbox` from the closure. If you choose rclone, do not call it
“backup”; see [`backup.md`](backup.md) for a real backup design.

## Verification

```sh
# Duplicate/wrong-layer check
nix why-depends /run/current-system ./result 2>/dev/null | head
nix path-info -S /run/current-system | tail -1

# Package presence
command -v feh zgrviewer uutils-procps paprefs rainloop peerflix-server || true
command -v imv mpv nvim

# Nix settings
nix show-config | grep -E '^(max-jobs|cores|download-buffer-size)'

# Virtualisation
systemctl status docker podman libvirtd ollama --no-pager
systemctl is-enabled libvirtd

# Flake checks
nix flake check --no-build
nix build .#checks.x86_64-linux.formatting --no-link

# MIME
xdg-mime query default image/png
xdg-mime query default video/mp4
xdg-mime query default text/plain
```

## Open questions

- Is any container workflow actually used (Docker, Podman, distrobox)?
- Are libvirt/VMs used? If yes, socket activation is enough?
- Is Dropbox required, or can it be removed?
- Is `peerflix-server` still used? If yes, isolate it; if no, remove.
- Is a printer used? If not, remove CUPS + Avahi.
- Is `corefonts` needed by any app/document?
- Is `texliveFull` staying in Home, or should it move to a devShell?
- Do you want `imv` as the `feh` alias, or no alias at all?
- Should Chrome or Firefox be the default browser for `http(s)`?