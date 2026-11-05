# Backup and restore

Priority: **P0**. There is currently no backup configuration. The laptop has no
full-disk encryption, so an encrypted backup is also the recovery plan for a
lost/stolen machine.

## Current state

- No `restic`, `borg`, `rclone`, or backup service is configured.
- `home/dropbox.nix` defines a Dropbox user service, but Dropbox is not a
  backup: it syncs (and propagates deletions), and it does not work reliably
  on this Hyprland session.
- The NixOS flake is a Git repository in `/home/spamdoodler/nixos`; it is the
  source of truth for the system and must be backed up.
- Photos/wallpapers live under `~/Pictures`; documents and university work are
  under `~/Uni`; projects are under `~/...` (discover exact paths before the
  first run).
- `flake.lock` is currently modified/uncommitted. Commit it before relying on
  the repo as a restore source.
- No LUKS/FDE. Backups must be encrypted; a stolen USB drive must not expose
  secrets.

## Decision needed

Pick a destination before implementing. Recommended baseline:

| Copy | Medium | Purpose |
|---|---|---|
| 1 | The laptop (working copy) | Not a backup |
| 2 | External USB SSD/HDD, kept at home | Fast local restore |
| 3 | Backblaze B2 (or Hetzner Storage Box) | Offsite, survives fire/theft |

**Recommendation:** `restic` to an external USB drive **and** Backblaze B2.
Two repositories, same snapshots. This satisfies 3-2-1 (three copies, two
media, one offsite) without a second cloud account.

Alternatives:

- **Hetzner Storage Box** — cheaper per TB in Europe, supports SFTP/restic via
  `sftp:`; good if you prefer EU hosting.
- **rsync.net** — expensive but reliable, plain SSH/SFTP.
- **S3-compatible** (Wasabi, Storj, etc.) — restic supports S3; watch egress
  fees and minimum storage durations.
- **Local-only USB** — better than nothing, but does not survive theft/fire.

Do not use Dropbox as the only backup. If you want Dropbox sync, use
`maestral` or `rclone` separately; see [`packages.md`](packages.md).

## Tool choice: restic

Use **restic**:

- encrypted, deduplicated, compressed repository;
- snapshot-based, so deletions do not propagate;
- native Backblaze B2, SFTP, S3, and local backends;
- simple `backup`, `forget`, `check`, `restore`, `mount` commands;
- packaged in nixpkgs and easy to run from systemd.

`rustic` is a Rust reimplementation with some nicer performance and config
features, but restic is more widely documented and has a larger recovery
ecosystem. Choose restic for the first backup; revisit rustic only if restic is
too slow.

`borg` is also good, but its repository model and cache are less convenient
for a single laptop with an external drive + B2. Do not run two backup systems
“for safety”; one tested system is better.

## What to back up

Back up:

- `/home/spamdoodler/nixos` (the flake, including `flake.lock`);
- `/home/spamdoodler/Documents`, `~/Uni`, `~/projects`, `~/src`, and any other
  work directories;
- `~/Pictures` (including wallpaper collections, if you want them);
- `~/.ssh` (encrypted inside the restic repo);
- selected `~/.config` (git, shell, nvim, hyprland, waybar, opencode), but not
  caches;
- `~/.local/share/opencode/auth.json` (secret; restic encrypts it);
- `/etc` (system config, SSH host keys, NetworkManager connections);
- `/var/lib/NetworkManager` if you rely on saved Wi-Fi profiles;
- browser bookmarks/passwords only if you accept that they are in the backup;
  Firefox/Chrome profiles contain caches, so exclude the cache directories.

Do **not** back up:

- `/nix/store` (rebuildable; huge);
- `/proc`, `/sys`, `/dev`, `/run`;
- `~/.cache`, `~/.local/share/Trash`, `~/.local/share/Steam`,
  `~/.local/share/containers`, `~/.opencode-tmp`;
- `node_modules`, `.direnv`, `target`, `result`, build outputs;
- VM images (`/var/lib/libvirt/images`) unless they are irreplaceable;
- `~/Downloads` by default;
- the restic cache itself.

If a directory contains secrets you do not want in the backup, exclude it
explicitly. Restic encryption protects the backup at rest, but a restored
laptop is still unencrypted.

## Repository layout

```text
/mnt/backup/restic                 # external USB, local repo
b2:bucket-name:nixsama             # Backblaze B2, offsite repo
```

Credentials:

```text
/etc/restic/password               # restic repository password, 0600 root
/etc/restic/b2.env                 # B2_ACCOUNT_ID / B2_ACCOUNT_KEY, 0600 root
/etc/restic/excludes               # exclude patterns
```

Never put these in the Nix store or in `home.file`. A systemd
`EnvironmentFile` with mode `0600` is appropriate. Keep a copy of the restic
password in a password manager and on paper in a safe place; without it the
backup is unrecoverable.

## Initial setup

```sh
# Local repository
sudo install -d -m 700 /mnt/backup/restic
sudo restic -r /mnt/backup/restic init

# Offsite repository (after configuring B2 credentials)
sudo sh -c '. /etc/restic/b2.env; restic -r b2:bucket-name:nixsama init'
```

Run the first backup manually and inspect it before enabling the timer:

```sh
sudo restic -r /mnt/backup/restic backup \
  --host NixSama --tag manual \
  --exclude-file /etc/restic/excludes \
  /home/spamdoodler /etc

sudo restic -r /mnt/backup/restic snapshots
sudo restic -r /mnt/backup/restic check
```

Then repeat to B2. If the first upload is large, run it on AC power and a
wired connection if possible.

## Exclude file

Start conservative; add paths only after checking they are caches:

```text
/home/spamdoodler/.cache
/home/spamdoodler/.local/share/Trash
/home/spamdoodler/.local/share/Steam
/home/spamdoodler/.local/share/containers
/home/spamdoodler/.opencode-tmp
/home/spamdoodler/Downloads
/home/spamdoodler/.local/share/restic
node_modules
.direnv
target
result
*.qcow2
*.iso
```

Restic's `--exclude-caches` also skips directories containing `CACHEDIR.TAG`.
Use it in addition to the explicit list. Verify what was skipped with
`restic snapshots --json` and a test restore, not by trusting the patterns.

## Systemd units

A system service can read `/home` and `/etc`. Run as root, with a low I/O
priority:

```nix
systemd.services.restic-local = {
  description = "Restic backup to external USB";
  serviceConfig = {
    Type = "oneshot";
    User = "root";
    EnvironmentFile = "/etc/restic/env";
    ExecStart = "${pkgs.restic}/bin/restic backup \
      --host NixSama --tag daily \
      --exclude-file /etc/restic/excludes \
      --exclude-caches \
      /home/spamdoodler /etc";
    Nice = 10;
    IOSchedulingClass = "idle";
  };
};

systemd.timers.restic-local = {
  description = "Daily restic backup";
  timerConfig = {
    OnCalendar = "daily";
    Persistent = true;
    RandomizedDelaySec = "30min";
  };
  wantedBy = ["timers.target"];
};
```

For B2, duplicate the service with `EnvironmentFile` containing the B2
credentials and `RESTIC_REPOSITORY=b2:...`. Do not run both at the same moment;
stagger them (local at 02:00, offsite at 03:00) or use `restic copy` after the
local backup. Test the copy syntax against the installed restic version before
relying on it.

If the laptop is often off at 02:00, `Persistent = true` runs the missed job
after the next boot. That is desirable for backups. Do not use
`ConditionACPower = true` unless you accept skipped backups on battery.

## Retention and pruning

```sh
restic forget --prune \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --keep-yearly 3
```

Run `forget --prune` weekly or monthly, not after every backup (prune is
expensive). Keep at least one snapshot older than the current laptop state so
a ransomware/mistake does not leave only compromised snapshots. For a small
home dataset, 7 daily + 4 weekly + 12 monthly is generous; adjust to disk
size.

Run a integrity check monthly:

```sh
restic check
restic check --read-data-subset=5%
```

`--read-data-subset` reads and verifies a random portion; a full
`--read-data` is expensive but worth doing once or twice a year if the repo is
small.

## Restore drills

A backup is not real until restored. Do this quarterly:

1. Boot a NixOS live USB (keep one).
2. Install `restic` (`nix-shell -p restic` or the live environment).
3. Set `RESTIC_REPOSITORY` and `RESTIC_PASSWORD_FILE`.
4. `restic snapshots`; choose a snapshot.
5. `restic restore latest --target /mnt/restore`.
6. Inspect `~/nixos/flake.nix`, `~/Documents`, and a photo.
7. Rebuild the system from the restored flake:
   `sudo nixos-rebuild switch --flake /mnt/restore/home/spamdoodler/nixos#NixSama`.
8. Record the date, snapshot ID, and any missing files.

Also test a **single-file** restore without a live USB:

```sh
restic restore latest --target /tmp/restore --include /home/spamdoodler/nixos/flake.nix
```

If you cannot restore the flake and rebuild, the backup is incomplete for this
system.

## Security and privacy

- Restic encrypts data and filenames; the repository password is critical.
- The external drive is encrypted by restic, but a restored laptop is not
  encrypted. Do not treat backup encryption as a substitute for FDE.
- B2 credentials are read/write keys; scope them to the bucket if possible and
  rotate them if the laptop is lost.
- Do not store the restic password in the same place as the backup drive.
- `.ssh` keys and `auth.json` are in the backup; protect the repo password
  accordingly.
- `~/Pictures/anime_wallpapers/nsfw` may be private; it is encrypted in the
  repo, but exclude it if you do not want it in cloud storage.
- Backups can capture secrets from shell history. Atuin's history filter helps
  but is not a guarantee; scrub history before the first backup if needed.

## Schedule summary

| Task | Frequency | Command |
|---|---|---|
| Local backup | Daily, persistent | systemd timer |
| Offsite backup | Daily, after local | systemd timer |
| `forget --prune` | Weekly/monthly | manual or timer |
| `check` | Monthly | manual |
| `check --read-data-subset=5%` | Monthly | manual |
| Restore drill | Quarterly | live USB |
| Rotate B2/restic credentials | Yearly or on loss | manual |

## Tasks

- [ ] Choose the offsite destination (B2 recommended).
- [ ] Buy/attach an external USB SSD/HDD with enough space.
- [ ] Install `restic`; create `/etc/restic/{password,b2.env,excludes}` with
      mode `0600`.
- [ ] Initialize local and offsite repositories.
- [ ] Run the first local backup; inspect `snapshots` and `check`.
- [ ] Run the first offsite backup.
- [ ] Add systemd services/timers; stagger them.
- [ ] Add `forget --prune` retention.
- [ ] Add monthly `check` (manual or timer).
- [ ] Commit `flake.lock` and the repo before the first backup.
- [ ] Perform a single-file restore test.
- [ ] Perform a full live-USB restore drill.
- [ ] Document the restore procedure in the root `README.md`.
- [ ] Exclude `.opencode-tmp`, caches, Steam, VMs, and build outputs.
- [ ] Decide whether photos/NSFW wallpapers go offsite.

## Verification

```sh
restic version
restic -r /mnt/backup/restic snapshots
restic -r /mnt/backup/restic check
restic -r /mnt/backup/restic stats
systemctl status restic-local.timer restic-local.service
journalctl -u restic-local -n 50 --no-pager
```

A successful timer with no snapshots is not a backup. Always verify
`snapshots` and a restore.

## Open questions

- External USB + B2, or a single destination?
- What is the budget per TB/month?
- Should `~/Pictures` and the NSFW wallpaper set go offsite?
- Is a quarterly restore drill realistic, or should it be monthly?
- Do you want `restic` on a system timer (root) or a user timer (home only)?
- Should Dropbox be replaced by `maestral`, `rclone`, or removed entirely?