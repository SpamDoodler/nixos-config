# Power saving and hibernation

Priority: **P1**. The machine is a Ryzen 5 7530U (6C/12T, 14 GiB RAM) with a
16 GiB disk swap partition and 7.5 GiB zram. `systemctl suspend` works;
hibernation is not reliable because NixOS does not know about the swap
partition and there is no `resume=` kernel parameter.

## Current state

| Item | Current | File |
|---|---|---|
| Power profile | `power-profiles-daemon` enabled | `system/powerManagement.nix:7` |
| Thermal daemon | `thermald` enabled (Intel-only) | `system/powerManagement.nix:8` |
| TLP / auto-cpufreq | disabled | `system/powerManagement.nix:13,26` |
| `powertop` auto-tune | disabled | `system/powerManagement.nix:30` |
| zram | zstd, 50% of RAM | `hardware/hardware.nix:18-22` |
| Disk swap | 16 GiB `/dev/nvme0n1p2`, active, **not declared** | `hardware/hardware-configuration.nix:30` |
| Swappiness | `10` | `system/boot.nix:13` |
| Wi-Fi powersave | `false` | `system/networking.nix:19` |
| CPU driver | `amd_pstate=guided` | `system/boot.nix:18` |
| Hibernate resume | `/sys/power/resume = 259:2`, but no `resume=` in cmdline | live system |

## Decisions

- Keep `linux_testing`.
- Remove `thermald`.
- Keep `power-profiles-daemon`; do **not** enable TLP at the same time.
- Increase swappiness; 10 is wrong for zram.
- Fix hibernation if the swap/resume configuration is sufficient; otherwise
  document suspend-only.

## 1. Remove thermald (P1)

`thermald` is an Intel thermal daemon and does nothing useful on this AMD
Barcelo APU. Remove:

```nix
services.thermald.enable = false;
```

Keep `power-profiles-daemon` and `upower`. Do not enable `tlp` or
`auto-cpufreq` alongside PPD.

- [ ] Remove `thermald`.
- [ ] Rebuild and confirm `systemctl status thermald` is not-found/inactive.
- [ ] Confirm `powerprofilesctl get` still works.

## 2. Swappiness and zram (P1)

With zram, the kernel should prefer compressed RAM over disk swap. `10` makes
it avoid swap until memory pressure is severe. Use `100` initially; the valid
range is 0–200.

```nix
boot.kernel.sysctl = {
  "vm.swappiness" = 100;
  "vm.vfs_cache_pressure" = 50;      # keep unless measurements disagree
  "vm.page-cluster" = 0;             # zram/SSD: no readahead clustering
  "vm.watermark_boost_factor" = 0;   # avoid excessive reclaim bursts
  "vm.watermark_scale_factor" = 125;
};
```

Notes:

- `vm.page-cluster = 0` is a common zram/SSD setting; benchmark before keeping
  it if you do heavy disk I/O.
- zram at 50% (≈7.5 GiB) is aggressive but does not reserve RAM; it only uses
  memory for compressed pages. Watch `zramctl` and `/proc/pressure/memory`.
- If the machine feels memory-starved, try `memoryPercent = 25` (≈3.75 GiB) and
  compare. Do not disable disk swap: it is needed for hibernation.
- `vm.swappiness = 150` is also defensible with zram; change one value at a
  time and measure.

- [ ] Set swappiness to 100.
- [ ] Add `page-cluster`, watermark, and boost settings.
- [ ] Record `zramctl` and `/proc/pressure/memory` before/after.
- [ ] Decide whether 50% zram is right after a week of normal use.

## 3. Hibernation fix (P1)

### Why it is broken

- `hardware-configuration.nix:30` has `swapDevices = []`, yet
  `/dev/nvme0n1p2` is active (systemd unit from an older generation or manual
  activation). NixOS does not generate the swap unit or resume configuration.
- `/proc/cmdline` has no `resume=`.
- `/sys/power/state` includes `disk`, and `/sys/power/resume` is `259:2`, but
  without `resume=` the initrd will not resume the image; the system boots
  fresh and the hibernated state is lost.
- The 16 GiB swap partition is large enough for 14 GiB RAM, but the image may
  not fit if RAM is full. Hibernation needs swap ≥ used RAM plus margin.
- zram cannot store a hibernation image. The 7.5 GiB zram device only holds
  compressed anonymous pages while awake; the image must go to the disk swap
  partition named in `resume=`. Keep that partition even with zram enabled.

### Proposed configuration

In `hardware/hardware-configuration.nix`:

```nix
swapDevices = [
  { device = "/dev/disk/by-uuid/d0d758fa-e216-457c-a0fe-f673beba13bc"; }
];
```

In `system/boot.nix`:

```nix
boot.resumeDevice = "/dev/disk/by-uuid/d0d758fa-e216-457c-a0fe-f673beba13bc";
```

`boot.resumeDevice` makes NixOS add `resume=UUID=...` and include the resume
logic in the initrd. Do not also hardcode a duplicate `resume=` in
`boot.kernelParams` unless you verify the generated cmdline.

Optional suspend-then-hibernate:

```nix
systemd.sleep.extraConfig = ''
  HibernateDelaySec=30min
'';
services.logind.settings.Login = {
  HandleLidSwitch = "suspend";
  HandleLidSwitchExternalPower = "suspend";
  HandleLidSwitchDocked = "ignore";
  HandleSuspendKey = "suspend";
  HandleHibernateKey = "hibernate";
};
```

### Verification

```sh
swapon --show
cat /proc/cmdline | tr ' ' '\n' | grep '^resume='
cat /sys/power/resume /sys/power/disk /sys/power/state
sudo systemctl hibernate
# After resume:
journalctl -b -u systemd-hibernate --no-pager | tail -30
```

If `systemctl hibernate` fails, check:

- `journalctl -u systemd-hibernate -b`
- swap size vs `MemTotal` and current usage
- `resume=` UUID matches the swap partition
- initrd contains the resume hook (`lsinitrd` on the initrd)
- firmware/BIOS hibernation support (some HP laptops are picky)
- whether the swap partition is actually active before hibernating

If it still fails, keep suspend-only and remove misleading `disk` claims from
the README. Do not enable hibernation on a laptop where resume is unreliable;
data loss is worse than a cold boot.

- [ ] Declare the swap partition in `swapDevices`.
- [ ] Set `boot.resumeDevice`.
- [ ] Add lid/suspend-key handling.
- [ ] Test `systemctl hibernate` and resume.
- [ ] If it fails, document suspend-only and stop.

## 4. Wi-Fi and peripheral power (P2)

`system/networking.nix:19` disables Wi-Fi powersave. This may be a workaround
for the RTL8852BE; test before changing.

```nix
networking.networkmanager.wifi.powersave = true;
```

Test for a week: throughput, latency, disconnects, suspend/resume. If unstable,
revert and document the reason. Also consider `iw dev wlan0 get power_save`.

Do not run `powertop --auto-tune` blindly. It can disable USB wakeup, keyboard
wakeup, or audio power states. If you try it, test suspend/resume and input
devices first.

## 5. Idle, display, and suspend (P1)

Use Hypridle (see [`security.md`](security.md)):

- dim/DPMS off after 5 minutes;
- lock after 10 minutes;
- suspend after 15–30 minutes on battery;
- lock before sleep, DPMS on after resume.

For Sway, use `swayidle` + `swaylock` only when Sway is tested separately.

- [ ] Add DPMS off/on.
- [ ] Add lock before suspend.
- [ ] Test lid close, suspend, resume, and external HDMI.

## 6. Measurement plan (P2)

Do not optimize by folklore. Measure:

```sh
powerprofilesctl get
upower -i "$(upower -e | grep BAT | head -1)" | \
  grep -E 'state|percentage|energy-rate|time to'
cat /sys/class/power_supply/BAT0/power_now 2>/dev/null
sudo powertop --time=60
sudo turbostat --quiet --show PkgWatt,Busy%,C1,C2,C3 --interval 5
sensors
zramctl
cat /proc/pressure/memory
```

Record: idle drain (%/hour), package power at idle, top wakeups, and battery
runtime under a repeatable load (browser + terminal). Change one thing at a
time.

Potential additions, in order:

1. `services.power-profiles-daemon` balanced profile on battery.
2. Wi-Fi powersave (if stable).
3. Hypridle DPMS/suspend.
4. `powertop` auto-tune (only after testing).
5. `scx_lavd` scheduler (experimental; not a first step).
6. `amdgpu` runtime PM / panel self-refresh (verify kernel support first).

## 7. GPU diagnostics (answer)

You do **not** need a permanent GPU diagnostics stack for daily use. Useful
one-off tools:

- `vainfo` (from `libva-utils`) — confirm VA-API decode/encode.
- `amdgpu_top` — AMD GPU utilization, clocks, power; better than `radeontop`
  for this iGPU.
- `nvtop` — multi-GPU process view; optional.
- `sensors` — already installed (`lm_sensors`).
- `vulkaninfo` — already available via `vulkan-tools`.

Install `vainfo` and `amdgpu_top` only if debugging video playback, GPU hangs,
or power. See [`tools.md`](tools.md).

## Open questions

- Is hibernation a hard requirement, or is suspend enough?
- Do you want suspend-then-hibernate after 30 minutes, or plain suspend?
- Is the RTL8852BE stable with powersave on?
- Should the laptop suspend on lid close when on AC power too?