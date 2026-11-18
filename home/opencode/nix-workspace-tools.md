## Workspace software

Run Python, SageMath, Macaulay2 (`M2`), Lean and Lake through the workspace's
local Nix flake, not through whichever versions happen to be on `PATH`.
Identify the relevant `flake.nix` and inspect `nix flake show` or the flake
source for the documented app, dev shell, or project wrapper. For example,
use `nix develop .#<shell> -c python …` (or `nix develop . -c …` for the
default shell), or `nix run .#<app> -- …` if the flake exposes an app.
Use the project's required wrapper when one exists. Record the command and
any material tool version in reproducible checks.

If the flake or required tool is missing, or the role has no shell access,
report that limitation and give the shell-capable lead the exact command
and inputs to run. Do not silently use a global installation, install
packages, or modify the flake or lockfile to make a check pass.
