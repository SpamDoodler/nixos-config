# Home Manager module. Replace the previous module, then rebuild normally.
# Do not also install pkgs.opencode or enable programs.opencode elsewhere.
# Native V2 configuration, checked against the OpenCode 2.1.1 schema.
# Trusted local work: Python/tests can execute arbitrary code, not a sandbox.
{
  pkgs,
  lib,
  ...
}: let
  model = "gpt-6-luna";
  # Use an explicitly supported default effort; variants remain selectable.
  rules = action: effect: resources:
    map (resource: {inherit action resource effect;}) resources;
  readOnlyPermissions = lib.concatMap (action: rules action "deny" ["*"]) [
    "edit"
    "shell"
    "subagent"
    "todowrite"
  ];
  # V2 arrays retain last-match-wins ordering through builtins.toJSON.
  permissions =
    rules "*" "ask" ["*"]
    ++ lib.concatMap (action:
      rules action "allow" ["*"]
      ++ rules action "deny" ["*.env" "*.env.*" "**/.env" "**/.env.*"]
      ++ rules action "allow" ["*.env.example" "**/.env.example"]
      ++ rules action "deny" ["**/*credential*" "**/*secret*"])
    ["read" "edit"]
    ++ lib.concatMap (action: rules action "allow" ["*"]) [
      "glob"
      "grep"
      "todowrite"
      "question"
      "webfetch"
    ]
    ++ rules "subagent" "deny" ["*"]
    ++ rules "subagent" "allow" ["explore" "review"]
    ++ rules "skill" "deny" ["*"]
    ++ rules "skill" "allow" ["nix-validation" "opencode-config-review" "exact-computation"]
    ++ rules "external_directory" "ask" ["*"]
    ++ rules "shell" "ask" ["*"]
    ++ rules "shell" "allow" [
      "git status*"
      "git diff*"
      "git log*"
      "python"
      "python *"
      "python3"
      "python3 *"
      "pytest"
      "pytest *"
      "rg *"
      "ls"
      "ls *"
      "mkdir *"
      "mktemp"
      "mktemp *"
      "nix eval *"
      "nix-instantiate --parse *"
      "alejandra --check *"
    ]
    ++ rules "shell" "deny" ["rm *" "sudo *" "git push*" "git reset --hard*" "git clean*"];
  agents = {
    general.disabled = true;
    scout.disabled = true;
    build.system = ''
      Handle small tasks directly. Delegate only bounded, independent codebase
      questions to explore or a supplied diff to review when a separate pass adds
      value. Give each specialist the objective, scope, relevant context and
      required evidence. Batch independent investigations of similar duration.
      Integrate and verify their findings; delegation is not proof of correctness.
    '';
    explore = {
      disabled = false;
      mode = "subagent";
      description = "Read-only codebase investigation with file locations and evidence";
      permissions = readOnlyPermissions;
      system = ''
        Answer the supplied codebase question using read, glob and grep.
        Read project instructions, keep scope bounded and exclude .opencode-tmp.
        Return relevant paths and line numbers, evidence, and unresolved questions.
        Do not implement changes or request shell access. Stop once answered.
      '';
    };
    review = {
      mode = "all";
      description = "Read-only review of supplied changes for actionable defects";
      permissions = readOnlyPermissions;
      system = ''
        Review the supplied diff or named files against the requested behavior
        and project instructions. Inspect surrounding code with read and search.
        Report concrete defects with severity, file/line, failure scenario and
        supporting evidence. Separate confirmed issues from unverified concerns.
        Avoid speculative style complaints. State explicitly when no actionable
        issues are found and identify verification gaps. Do not change files or
        request shell access. Ask for the diff if it was not supplied.
      '';
    };
  };
  commands = {
    review = {
      description = "Review current changes for concrete defects without editing";
      agent = "build";
      template = ''
        Review scope: $ARGUMENTS (default: current working-tree changes).
        Inspect git status and diffs, including staged changes; read relevant
        untracked files only when in scope. Do not edit files or run project code.
        Supply the relevant diff, objective and context to the review specialist.
        Validate its findings against source. Return actionable findings with
        severity, file/line and evidence, then verification gaps. If no defects
        are found, say so. Do not commit or activate changes.
      '';
    };
    verify = {
      description = "Run the smallest decisive checks for the requested changes";
      agent = "build";
      template = ''
        Verify $ARGUMENTS (default: current changes). Read project instructions
        and identify acceptance criteria. Use nix-validation for Nix changes.
        Choose the smallest decisive checks, run them, and report exact commands,
        results and limitations. Do not edit files, install dependencies, update
        lockfiles, commit, deploy or activate. Stop after checks pass; on failure
        explain the failure and the next targeted check or fix.
      '';
    };
    investigate = {
      description = "Evidence-led investigation of a symptom or failure";
      agent = "build";
      template = ''
        Investigate: $ARGUMENTS. Read project instructions. Gather focused logs
        and a minimal reproduction, distinguish observations from hypotheses,
        and identify the root cause with evidence. Delegate bounded independent
        source questions to explore if useful. Propose the smallest fix and its
        verification. Implement only if the request explicitly asks for a fix.
        Do not commit or activate changes.
      '';
    };
    handoff = {
      description = "Summarize session state for continuation";
      agent = "build";
      template = ''
        Produce a compact handoff for $ARGUMENTS using the current conversation.
        Include objective, decisions, changed files, exact checks and outcomes,
        unresolved issues, and ordered next steps. Preserve mathematical
        assumptions and distinguish proofs from computations. Do not run tools
        or create files unless explicitly requested.
      '';
    };
  };
  launcher = pkgs.writeShellApplication {
    name = "opencode";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      # Parse known options without treating prompt/option values as flags.
      # Unknown/array options conservatively skip scratch; upstream parses argv.
      workspace="$PWD"
      args=("$@")
      scratch="''${OPENCODE_WORKSPACE_TMP:-1}"
      mode=""
      for ((i=0; i<''${#args[@]}; i++)); do
        case "''${args[i]}" in
          --)
            if [[ -z "$mode" && -d "''${args[i+1]:-}" ]]; then
              workspace="''${args[i+1]}"
            fi
            break ;;
          --dir) workspace="''${args[i+1]:-$workspace}"; i=$((i+1)) ;;
          --dir=*) workspace="''${args[i]#--dir=}" ;;
          --attach|--attach=*|--help|--help=*|-h|--version|--version=*|-v) scratch=0 ;;
          --log-level|--port|--hostname|--mdns-domain|--model|-m|--session|-s|--prompt|--agent|--command|--format|--title|--password|-p|--username|-u|--variant|--replay-limit)
            i=$((i+1)) ;;
          --print-logs|--pure|--mdns|--continue|-c|--fork|--auto|--mini|--no-replay|--share|--thinking|--interactive|-i) ;;
          --*=*) ;;
          -*) scratch=0 ;;
          *)
            if [[ -z "$mode" ]]; then
              mode="''${args[i]}"
              case "$mode" in
                run|serve|web|pr) ;;
                auth|providers|models|session|export|import|upgrade|uninstall|attach|acp|mcp|agent|stats|debug|completion|github|plugin|plug|db) scratch=0 ;;
                *) if [[ -d "$mode" ]]; then workspace="$mode"; else scratch=0; fi ;;
              esac
            fi ;;
        esac
      done
      if [[ "$scratch" != 0 ]]; then
        workspace="$(realpath -e -- "$workspace")"
        root="$workspace/.opencode-tmp"
        # Another launcher may create it first; validate the winner below.
        if ! mkdir -m 700 -- "$root" 2>/dev/null && [[ ! -d "$root" ]]; then
          echo 'opencode: could not create scratch directory.' >&2
          exit 1
        fi
        if [[ -L "$root" || ! -d "$root" || ! -O "$root" || "$(stat -c %a -- "$root")" != 700 ]]; then
          echo 'opencode: .opencode-tmp must be an owned, private directory (0700).' >&2
          exit 1
        fi
        if [[ ! -e "$root/.gitignore" && ! -L "$root/.gitignore" ]]; then
          # Publish complete contents atomically, without replacing an existing file.
          ignore="$(mktemp "$root/.ignore-XXXXXXXX")"
          printf '*\n' > "$ignore"
          if ! ln -- "$ignore" "$root/.gitignore" 2>/dev/null; then
            if [[ ! -e "$root/.gitignore" && ! -L "$root/.gitignore" ]]; then
              rm -f -- "$ignore"
              echo 'opencode: could not create scratch .gitignore.' >&2
              exit 1
            fi
          fi
          rm -f -- "$ignore"
        fi
        if [[ -L "$root/.gitignore" || ! -f "$root/.gitignore" || ! -O "$root/.gitignore" || "$(cat -- "$root/.gitignore")" != '*' ]]; then
          echo 'opencode: unexpected scratch .gitignore; refusing to overwrite.' >&2
          exit 1
        fi
        TMPDIR="$(mktemp -d "$root/s-XXXXXXXX")"
        export TMPDIR TMP="$TMPDIR" TEMP="$TMPDIR"
      fi
      exec ${pkgs.opencode}/bin/opencode "$@"
    '';
  };
in {
  assertions = [
    {
      assertion =
        lib.versionAtLeast (lib.getVersion pkgs.opencode) "2.1.1"
        && lib.versionOlder (lib.getVersion pkgs.opencode) "3.0.0";
      message = "This module targets OpenCode V2 >=2.1.1 and <3.0.0.";
    }
  ];
  home.packages = [launcher pkgs.nixd pkgs.alejandra];

  # Permissions use ordered arrays, not V1 tool-keyed maps.
  xdg.configFile."opencode/opencode.jsonc".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "model": "openai/${model}",
      "default_agent": "build",
      "share": "disabled",
      "update": "disable",
      "plugins": [],
      "formatter": {"nixfmt": {"disabled": true}, "alejandra": {
        "command": ["${pkgs.alejandra}/bin/alejandra", "$FILE"],
        "extensions": [".nix"]
      }},
      "agents": ${builtins.toJSON agents},
      "commands": ${builtins.toJSON commands},
      "providers": {"openai": {"models": {"${model}": {
        "settings": {"reasoningEffort": "high", "textVerbosity": "low"},
        "variants": [
          {"id": "economy", "settings": {"reasoningEffort": "low"}},
          {"id": "balanced", "settings": {"reasoningEffort": "medium"}},
          {"id": "deep", "settings": {"reasoningEffort": "high"}}
        ]
      }}}},
      "experimental": {"todo": true},
      "watcher": {"ignore": ["**/.opencode-tmp/**"]},
      "permissions": ${builtins.toJSON permissions}
    }
  '';
  xdg.configFile."opencode/AGENTS.md".text = builtins.readFile ./instructions.md;
  xdg.configFile."opencode/skills/nix-validation/SKILL.md".text = builtins.readFile ./nix-validation.md;
  xdg.configFile."opencode/skills/opencode-config-review/SKILL.md".text = builtins.readFile ./opencode-config-review.md;
  xdg.configFile."opencode/skills/exact-computation/SKILL.md".text = builtins.readFile ./exact-computation.md;
  # Scratch opt-out: OPENCODE_WORKSPACE_TMP=0 opencode
  # V2 has no LSP tools; use targeted lint/typecheck/compiler commands instead.
  # Delete old .opencode-tmp sessions only after processes exit; exclude from backups.
  # Project instructions/config remain active. No credentials belong in this file.
}
