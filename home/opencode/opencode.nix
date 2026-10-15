# Home Manager module. Replace the previous module, then rebuild normally.
# Do not also install pkgs.opencode or enable programs.opencode elsewhere.
# Tested with OpenCode 1.18.35; keep your flake.lock pinned.
# Trusted local work: Python/tests can execute arbitrary code, not a sandbox.
{
  pkgs,
  lib,
  ...
}: let
  model = "gpt-6-luna";
  # Use an explicitly supported default effort; variants remain selectable.
  readOnlyPermissions = {
    edit = "deny";
    bash = "deny";
    task = "deny";
    todowrite = "deny";
  };
  agents = {
    general.disable = true;
    scout.disable = true;
    build.prompt = ''
      Handle small tasks directly. Delegate only bounded, independent codebase
      questions to explore or a supplied diff to review when a separate pass adds
      value. Give each specialist the objective, scope, relevant context and
      required evidence. Batch independent investigations of similar duration.
      Integrate and verify their findings; delegation is not proof of correctness.
    '';
    explore = {
      disable = false;
      mode = "subagent";
      description = "Read-only codebase investigation with file locations and evidence";
      permission = readOnlyPermissions;
      prompt = ''
        Answer the supplied codebase question using read, glob, grep and LSP.
        Read project instructions, keep scope bounded and exclude .opencode-tmp.
        Return relevant paths and line numbers, evidence, and unresolved questions.
        Do not implement changes or request shell access. Stop once answered.
      '';
    };
    review = {
      mode = "all";
      description = "Read-only review of supplied changes for actionable defects";
      permission = readOnlyPermissions;
      prompt = ''
        Review the supplied diff or named files against the requested behavior
        and project instructions. Inspect surrounding code with read/search/LSP.
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
      # Expose LSP queries without enabling unrelated experimental features.
      export OPENCODE_EXPERIMENTAL_LSP_TOOL="''${OPENCODE_EXPERIMENTAL_LSP_TOOL:-true}"
      # Supply language servers through Nix or project dev shells, not downloads.
      export OPENCODE_DISABLE_LSP_DOWNLOAD=true
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
        lib.versionAtLeast (lib.getVersion pkgs.opencode) "1.18.30"
        && lib.versionOlder (lib.getVersion pkgs.opencode) "2.0.0";
      message = "This module targets OpenCode V1 >=1.18.30 and <2.0.0.";
    }
  ];
  home.packages = [launcher pkgs.nixd pkgs.alejandra];

  # Literal JSON preserves last-match-wins permission ordering.
  xdg.configFile."opencode/opencode.jsonc".text = ''
    {
      "$schema": "https://opencode.ai/config.json",
      "model": "openai/${model}",
      "default_agent": "build",
      "share": "disabled",
      "autoupdate": false,
      "plugin": [],
      "lsp": {"nixd": {
        "command": ["${pkgs.nixd}/bin/nixd"], "extensions": [".nix"]
      }},
      "formatter": {"nixfmt": {"disabled": true}, "alejandra": {
        "command": ["${pkgs.alejandra}/bin/alejandra", "$FILE"],
        "extensions": [".nix"]
      }},
      "agent": ${builtins.toJSON agents},
      "command": ${builtins.toJSON commands},
      "provider": {"openai": {"models": {"${model}": {
        "options": {"reasoningEffort": "high", "textVerbosity": "low"},
        "variants": {
          "economy": {"reasoningEffort": "low"},
          "balanced": {"reasoningEffort": "medium"},
          "deep": {"reasoningEffort": "high"}
        }
      }}}},
      "experimental": {"batch_tool": true},
      "watcher": {"ignore": ["**/.opencode-tmp/**"]},
      "permission": {
        "*": "ask",
        "read": {"*": "allow", "*.env": "deny", "*.env.*": "deny",
          "**/.env": "deny", "**/.env.*": "deny",
          "*.env.example": "allow", "**/.env.example": "allow",
          "**/*credential*": "deny", "**/*secret*": "deny"},
        "edit": {"*": "allow", "*.env": "deny", "*.env.*": "deny",
          "**/.env": "deny", "**/.env.*": "deny",
          "*.env.example": "allow", "**/.env.example": "allow",
          "**/*credential*": "deny", "**/*secret*": "deny"},
        "glob": "allow", "grep": "allow", "list": "allow",
        "todowrite": "allow", "question": "allow",
        "lsp": "allow",
        "task": {"*": "deny", "explore": "allow", "review": "allow"},
        "skill": {"*": "deny", "nix-validation": "allow",
          "opencode-config-review": "allow", "exact-computation": "allow"},
        "webfetch": "allow",
        "external_directory": "ask", "doom_loop": "ask",
        "bash": {
          "*": "ask",
          "git status*": "allow", "git diff*": "allow", "git log*": "allow",
          "python": "allow", "python *": "allow",
          "python3": "allow", "python3 *": "allow",
          "pytest": "allow", "pytest *": "allow",
          "rg *": "allow", "ls": "allow", "ls *": "allow",
          "mkdir *": "allow", "mktemp": "allow", "mktemp *": "allow",
          "nix eval *": "allow", "nix-instantiate --parse *": "allow",
          "alejandra --check *": "allow",
          "rm *": "deny", "sudo *": "deny", "git push*": "deny",
          "git reset --hard*": "deny", "git clean*": "deny"
        }
      }
    }
  '';
  xdg.configFile."opencode/AGENTS.md".text = builtins.readFile ./instructions.md;
  xdg.configFile."opencode/skills/nix-validation/SKILL.md".text = builtins.readFile ./nix-validation.md;
  xdg.configFile."opencode/skills/opencode-config-review/SKILL.md".text = builtins.readFile ./opencode-config-review.md;
  xdg.configFile."opencode/skills/exact-computation/SKILL.md".text = builtins.readFile ./exact-computation.md;
  # WebSockets are experimental. Opt out: OPENCODE_EXPERIMENTAL_WEBSOCKETS=false opencode
  # Scratch opt-out: OPENCODE_WORKSPACE_TMP=0 opencode
  # LSP query opt-out: OPENCODE_EXPERIMENTAL_LSP_TOOL=false opencode
  # Built-in language support stays enabled; missing servers must be supplied locally.
  # Delete old .opencode-tmp sessions only after processes exit; exclude from backups.
  # Project instructions/config remain active. No credentials belong in this file.
}
