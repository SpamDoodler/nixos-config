# Cleanliness, best practice, and maintainability

Priority: **P1**, ongoing goal alongside the next Neovim/AI batch. Static audit
performed 2026-11-09 against the working tree, including the pending todo edits
and pre-existing `flake.lock` change. This document approves no configuration
change, package removal, activation, or lock update.

## Pre-Neovim fix batch (2026-11-09)

The user subsequently approved doing concrete fixes before preference changes.
The following bounded batch has been implemented and checked, without activation:

- [x] Render RTW89 booleans explicitly as `1` / `0`; defaults remain unchanged.
- [x] Add a flake check for default, mixed true/false, and disabled configurations.
- [x] Fix stale Waybar test expectations for UID scoping and wrapped processes.
- [x] Expose desktop smoke tests as a flake check; replace mocked desktop runtime
      dependencies too, so tests do not build a real compositor/Waybar closure.
- [x] Declare the production Waybar script's `id` dependency via coreutils.
- [x] Guard the hy3 workaround to old `0.56.0.1` with Hyprland `0.57.x`; retain
      upstream releases otherwise. The pending lock already supplies hy3 0.57.0.

Verification:

```sh
alejandra --check flake.nix hardware/custom-rtw89.nix system/patches.nix \
  tests/desktop-scripts.nix home/desktop-scripts.nix
nix build --no-write-lock-file --no-link \
  .#checks.x86_64-linux.desktop-scripts .#checks.x86_64-linux.rtw89-options
```

These checks passed, as did parsing and full-system toplevel evaluation. A
separate expression checked hy3's old-version patch path, current upstream
identity, simulated newer-version passthrough, and incompatible-pair rejection.
The existing pre-batch `flake.lock` changes were not updated or reverted.

**Remaining build gate:** a full-system dry run on the pending lock reports
774 derivations to build and 5.8 GiB to fetch (16.1 GiB unpacked). The full build
was not launched as part of this small fix batch. No activation, Wi-Fi hardware
test, or live desktop test was performed. Before calling the system baseline
verified, build that lock explicitly and check any new rolling-release failures.
The first offline unit-test build failed during dependency fetching; after
removing unnecessary mocked-package dependencies and allowing substitutes, the
final unit-test build passed. No Sway configuration or production script changed.

The findings below retain their original audit-time evidence. The completed
items above supersede the corresponding broken-state descriptions; uncompleted
subtasks (formatting gate, wallpaper failure paths, wrapper checks) remain open.

## Policy: bleeding edge first, maintainable by design

- Keep nixos-unstable, Home Manager master following nixpkgs, `linux_testing`,
  and timely application/plugin upgrades. Do not solve maintenance by freezing
  everything on stable or disabling desired features.
- `flake.lock` makes the chosen revision reproducible; it is not a reason to
  avoid updates. Use small, reviewable upgrades, compatibility checks, and a
  known-good rollback generation instead of permanent pins.
- Prefer one authoritative owner for a package, setting, service, or action.
  Use typed module options and structured configuration where practical.
- Keep the existing single-host structure unless an actual second consumer
  justifies abstraction. No mandatory flake framework, Nixvim migration,
  directory renaming campaign, or custom option for every constant.
- Keep `texliveFull`, TTY1 + `start-hyprland`, Waybar, `system/patches.nix`,
  the 512 MB download buffer, and the documented Hyprland fallback. Do not
  change or delete Sway until its separate output issue is tested.
- Cleanup must preserve behavior unless the behavior change is explicitly
  approved. Separate formatting, refactors, dependency updates, and fixes.

## What already works well

- `flake.nix:5–12` uses upstream rolling branches and makes Home Manager follow
  nixpkgs, limiting package-set drift.
- `flake.nix:35–38` shares the system package set with Home Manager. Keep
  overlays system-side so they actually reach those packages.
- `system/system.nix:6–18` and `home/spamdoodler.nix:6–22` have explicit imports;
  active module ownership is discoverable without a framework.
- Neovim plugins are Nix-managed, and desktop script tests already exist.
  Build on these mechanisms rather than introducing parallel installers.
- State versions are explicit (`system/system.nix:23`,
  `home/spamdoodler.nix:24`). Their different values are not a defect; never
  bump them merely because packages or the lock are upgraded.

## Evidence-backed findings

Line references are audit-time locations, not permanent identifiers. Recheck
the source before implementing; evidence below distinguishes observed facts
from changes that need a usage or runtime test.

### 1. Give rolling-release workarounds a lifecycle (P1)

**Evidence:** `system/patches.nix:8–21` always replaces hy3 with `0.57.0`, even
if a future nixpkgs ships something newer. The OpenCode dependency hash override
at `:24–33` is version-guarded, but lacks an explanation of the failure and
upstream resolution. `home/opencode/opencode.nix:227–234` accepts the broad
OpenCode range `>=2.1.1 <3.0.0`, not proof of compatibility with every release.

- [ ] Retain `patches.nix`; bound each override to the affected package/ABI
      combination. Do not keep forcing an old plugin onto a new compositor.
- [ ] Record failure symptom, affected version(s), upstream reference if known,
      validation command, and removal condition beside each workaround.
- [ ] Verify the effective compositor/plugin package pair on lock updates.
      A deliberate compatibility failure is better than a silently stale pin.
- [ ] Cover OpenCode wrapper/config behavior with targeted tests, rather than
      treating the major-version assertion as a complete compatibility check.

### 2. Add one discoverable verification entry point (P1)

**Evidence:** `flake.nix:43–51` exposes a formatter and one project shell but
no `checks` output. `tests/desktop-scripts.nix` is therefore not automatically
run by `nix flake check`. No tracked CI workflow or root README was found.

- [ ] Expose existing desktop tests through `checks.x86_64-linux`, along with
      formatting. Verify dependencies come from the intended package set;
      `pkgs` imported at `flake.nix:22` is separate from NixOS's overlayed pkgs.
- [ ] Add headless candidate-Neovim startup checks during the editor batch and
      focused wrapper tests during OpenCode changes.
- [ ] Document cheap parse/evaluation checks, actual check builds, and a full
      system build as separate tiers. `nix flake check --no-build` does not run
      test derivations, and parse success does not prove option validity.
- [ ] Keep an explicit full-system build gate for package/ABI upgrades; cheap
      checks cannot establish that the system closure compiles.
- [ ] Add a small devShell for tools contributors actually use. Do not require
      globally installed linters, live API keys, or network access for unit tests.
- [ ] Add CI only after the local command works; CI should reuse it, not become
      a second independent list of checks. No automatic activation or secrets.

See `maintenance.md` for general operational checks, not another test runner.

### 3. Clarify package and configuration ownership (P1)

**Evidence:** `system/programs.nix:27,36,40,69,78` installs Starship, Alacritty,
Neovim, bat, and ImageMagick; Home Manager also enables the corresponding
programs or installs ImageMagick (`home/packages.nix:31`). Oh My Zsh is both
listed at `home/packages.nix:8` and enabled at `home/shell.nix:16–20`.
`system/programs.nix:11–14` hardcodes `HYPRLAND_CONFIG`, while
`home/hyprland/hyprland_hy_lua.nix:9` derives it from XDG configuration.

- [ ] Make an ownership inventory: system recovery/admin tools, user programs,
      editor-only dependencies, and project development dependencies.
- [ ] Remove redundant explicit packages where a program module already owns
      installation. Identical derivations do not necessarily duplicate store
      bytes; the confirmed problem is ambiguous ownership and executable choice.
- [ ] Decide whether system-wide Neovim is an intentional root/recovery editor
      before removing it; also consider `system/programs.nix:84` (`EDITOR`).
- [ ] Unify `HYPRLAND_CONFIG` ownership or derive both necessary consumers from
      one definition. Test fresh TTY/graphical login inheritance before removal.
- [ ] Move project-only libraries/toolchains out of `system/programs.nix:31,56–59,67`
      once consumers are identified. Global installation is not a project build
      dependency declaration. Do not remove a compiler just for aesthetic purity.

Detailed package choices belong in `packages.md`; editor ownership in `nvim.md`.

### 4. Fix the hardware option's false case (P1, correctness)

**Evidence:** `hardware/custom-rtw89.nix:13–28` defines boolean options;
`:39–41` interpolates them with `toString`. The audit's exact evaluation was:

```text
nix eval --json --expr '{ trueString = toString true; falseString = toString false; }'
{"falseString":"","trueString":"1"}
```

Thus a future `false` setting generates an empty parameter value instead of
explicit `0`. Defaults are true; no current Wi-Fi failure was demonstrated.

- [ ] Serialize boolean kernel options explicitly as `1` / `0`.
- [ ] Add render/evaluation tests for enabled, disabled, and mixed values.
- [ ] Document why each RTL8852BE workaround is needed and how to retest it on
      new testing kernels. Removing workarounds requires a separate hardware test.

### 5. Make the editor baseline smaller before adding AI (P1)

**Evidence:** `home/nvim/nvim.nix:21–42` includes Mason, all Treesitter grammars,
and multiple formatter/linter plugins; `:44–55` explicitly assembles Lua files.
`lua/setup/gui.lua:15–18` and `lua/plugins/treesitter.lua:5–36` under `home/nvim/`
both configure Treesitter, with conflicting regex highlighting choices.
`lua/plugins/treesitter.lua:1` assigns a runtime parser installation directory.

- [ ] Execute the foundation cleanup in `nvim.md` before adding AI dependencies:
      one parser setup, one formatter owner, explicit snippets and server tools.
- [ ] Validate plugin APIs against pinned source on upgrades; Nix pins a package,
      not the correctness of handwritten Lua options for that package.
- [ ] Keep AI-specific Lua separate from core editing and fail gracefully when
      credentials/network are absent; normal startup must remain offline-capable.

### 6. Remove ambiguity, not useful fallback paths (P2)

**Evidence:** `home/opencode/opencode_old.nix` (319 lines) and
`home/nvim/lua/init_old.lua` (36 lines) have no active references in the inspected
modules. `home/nvim/lua/luasnip-snippets.lua` (100 lines) is absent from the
explicit `initLua` assembly. Git already preserves historical versions.

- [ ] Delete confirmed obsolete `_old` copies after checking import/source
      references. Load and test the snippets or remove the unused file.
- [ ] Maintain a short map of active entrypoints and intentional fallbacks;
      do not classify all unimported `.conf`/`.nix` files as dead automatically.
- [ ] Do not delete `hyprland_hy3.nix` or Sway as part of dead-file cleanup.

### 7. Finish small ownership cleanups (P2)

**Evidence:** Agnoster is selected in `home/shell.nix:19` while
`home/starship.nix:6–9` enables a different prompt. Its time settings at `:17–18`
are not referenced by the explicit format. `fonts/fonts.nix:11,17` repeats
`noto-fonts`; `:18` lists Pango, a text-layout library, among font packages.
`system/services.nix:78–85` sets DNSSEC/DoT under disabled resolved.

- [ ] Pick one prompt owner; retain wanted shell plugins independently. Add
      `$time` to Starship's format only if wanted, otherwise remove dead settings.
- [ ] Remove the duplicate font entry and Pango from the font list. Keep font
      family/TeX choices separate; overlapping CJK families need glyph testing.
- [ ] Remove or clearly label inactive resolver settings as a proposal. Changing
      active DNS routing is a separate behavior change, not cosmetic cleanup.

### 8. Establish a consistent formatting baseline (P2)

**Observed check:** `git ls-files -z '*.nix' | xargs -0 alejandra --check`
inspected 40 tracked Nix files; six require formatting:

- `home/hyprland/hyprland.nix`
- `home/waybar.nix`
- `system/locals.nix`
- `system/environment.nix`
- `home/xdg.nix`
- `system/patches.nix`

- [ ] Keep Alejandra as the existing Nix formatter; make the initial cleanup a
      formatting-only change, separate from fixes or lock updates.
- [ ] Add Lua/shell formatting and linting only with a reproducible toolchain
      and scoped initial changes. Remove genuinely unused arguments/imports;
      do not suppress entire files or blindly apply linter rewrites.
- [ ] Consider `.editorconfig` for whitespace/final-newline conventions. Do not
      reflow all Markdown or introduce a formatting framework without need.

### 9. Make repository documentation trustworthy (P1)

**Evidence:** no root `README.md` is tracked; `.gitignore:1` only excludes
`.opencode-tmp`. `docs/todos/security.md:142–144` still says there is no lock/
idle/notification/polkit setup although `home/security.nix:2–67` configures it.
`docs/todos/backup.md:10–12` describes the removed Dropbox module as current.
`docs/todos/opencode.md:11–15` contains historical version/permission claims.

- [ ] Write a concise root README: host/user scope, entrypoints, build/test/
      activation commands, lock update workflow, patch inventory, secret boundary,
      and recovery. Link the todo index rather than duplicating its backlog.
- [ ] Label dated observations as historical; separate implemented configuration,
      runtime-verified behavior, proposals, and open decisions. Mark checkboxes
      complete only with the corresponding evidence; do not infer key rotation.
- [ ] Replace fragile line-only documentation with file paths plus setting names
      where possible; keep line references for dated audit evidence.
- [ ] Extend ignore rules for known build outputs (`/result`, `/result-*`,
      `.direnv/`) as needed; scope VM/ISO rules to actual artifact locations so
      legitimate fixtures are not hidden. Never use ignore rules as secret storage.

### 10. Repair stale script tests and strengthen failure coverage (P1)

**Evidence:** `scripts/waybar.sh:14–17` scopes process matching to the current
UID and recognizes `.waybar-wrapped`, but `tests/desktop-scripts.nix:89–93`
still expects `pgrep -x waybar` / `pkill -x waybar`. The mock at `:5–6` logs
real arguments, so those expectations no longer match. This is a confirmed
source mismatch; the test derivation was not built here.

`scripts/hyprback.sh:11–16` selects any regular file and unloads all wallpapers
before a successful replacement preload. `scripts/set_wallpapers.sh:9–22`
assumes the state file and a nonempty image collection. Tests exercise
happy-path mock responses, not empty directories or failed preload.

- [ ] Update Waybar expectations to include UID scoping and both process names,
      not weaken production behavior to satisfy old assertions.
- [ ] Filter supported images, handle missing/empty directories and initial
      state, and retain the current wallpaper until its replacement is ready.
- [ ] Add failure-mode tests and preserve argument boundaries in mocks (logging
      only `$*` cannot distinguish one argument containing spaces from several).
- [ ] Record Sway's separate issues at `scripts/wallpapers.sh:8–10`: ungrouped
      `find` predicates and a selected pathname not escaped for Sway's parser.
      Defer implementation/runtime validation to the dedicated Sway test batch.
      Quoting a whole shell argument does not quote its embedded pathname for
      the compositor's command parser.

Detailed wallpaper behavior belongs in `wallpapers.md`; this section owns
testing and shared-helper consistency goals.

### 11. Keep fallback and example workflows maintainable too (P2)

**Evidence:** `home/hyprland/hyprland_hy3.nix:112–113,163–167` launches mutable
scripts from `$HOME/nixos/scripts`, while the active Lua module uses packaged
scripts and a managed rotation service (`home/hyprland/hyprland_hy_lua.nix:37–51`).
The intentional fallback depends on checkout location instead of the same
packaged implementation. `projects/ai-supercollider/README.md:16` describes a
short texture, but `sessions/01-first-sound.scd:11–20` under that project starts
infinite patterns; its stop instruction is only a source comment.

- [ ] Preserve the Hyprlang fallback and document its supported entrypoint.
      Reuse packaged desktop helpers where compatible, then manually test
      switching to and from it; do not assume parity with the Lua configuration.
- [ ] Check whether older `hyprland.nix` / `hyprland.conf` have an external/manual
      recovery role before removal. Document one intentional fallback rather than
      leaving several unexplained lookalikes.
- [ ] Either bound the SuperCollider example or document continuous playback
      and a workable stopping procedure beside the CLI command. Keeping this
      small project in the repo is not itself a maintenance defect.

## Delivery order and acceptance

1. **Alongside Neovim:** foundation cleanup, candidate editor smoke tests,
   one AI UI/completion owner, and consistent keymaps (`nvim.md`).
2. **Small correctness batch:** hardware boolean rendering, stale Waybar test
   assertions, and workaround lifecycle safeguards, with regression checks.
3. **Repository guardrails:** expose tests, formatting baseline, README and
   stale-doc reconciliation; optionally CI after the checks work locally.
4. **Ownership cleanup:** packages, prompt, fonts, confirmed dead files; preserve
   root recovery tools and intentional fallbacks until usage is clarified.

For each batch, record changed behavior, exact checks, limitations, and rollback.
Compare representative rendered configs or effective values before/after a
supposed behavior-preserving refactor. Build before activation; fresh-login,
hardware, editor interaction, and external API tests remain explicit manual gates.
Do not accumulate an architecture rewrite ahead of the desired AI workflow.

## Audit limitations

This was a source/ownership audit plus the formatting and boolean-expression
checks above, not a full build, security audit, license audit, or hardware test.
Optional linters were not installed to perform it. Existing pending documentation
and lock changes were preserved. Runtime claims in older todos were not taken
as fresh measurements. Research-tool compatibility remains a separate pilot.
