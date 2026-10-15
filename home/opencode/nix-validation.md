---
name: nix-validation
description: Validate Nix, NixOS and Home Manager changes with targeted checks, without activation
---
Read project instructions, flake outputs and the changed modules first.
Identify the exact host/user/output; never guess the configuration name.
Use the project formatter (flake formatter or documented tool) and check
formatting without rewriting unrelated files. Parse changed Nix files when
useful, then evaluate the affected option/output or module assertions.
Prefer --offline and --no-write-lock-file for checks when inputs are cached.
Flake source filtering excludes untracked files: report this if it prevents
validation; do not stage files without instruction. Use a justified impure
local import only for a focused module check, and report that distinction.
A parse is not evaluation; evaluation is not a build; a build is not activation.
Build the smallest relevant derivation only when evaluation cannot establish
correctness. Do not update inputs, switch, deploy, or activate without an
explicit request. Do not use nix flake check as a substitute for evaluating
a NixOS configuration when the flake declares no relevant checks.
Report exact commands, outcomes, failed assertions and material limitations.
Stop after decisive checks pass; do not repeat broad checks without reason.
