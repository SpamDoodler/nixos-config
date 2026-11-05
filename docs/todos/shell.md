# Shell

Priority: **P1/P2**. The shell works, but the prompt stack is doubled, the
DeepSeek key is exported to every process, and `nix develop` drops the user
into a bare Bash prompt with none of the aliases, completions, or AI helpers.

## Current state

| Item | Current | File |
|---|---|---|
| Shell | zsh + Bash fallback | `home/shell.nix:6,34` |
| Prompt | Oh My Zsh `agnoster` **and** Starship | `home/shell.nix:16-20`, `home/starship.nix` |
| OMZ plugins | `git z sudo colored-man-pages` | `home/shell.nix:18` |
| Autosuggestions / highlighting | enabled | `home/shell.nix:8-9` |
| zoxide | enabled with `--cmd cd` | `home/shell.nix:36-41` |
| direnv + nix-direnv | enabled | `home/shell.nix:43-46` |
| Global secret | `export DEEPSEEK_API_KEY=$(cat ~/.deepseek_key)` | `home/shell.nix:21-23` |
| `MODELS` | `"$HOME/models"` | `home/shell.nix:26-28` |
| Aliases | `ls`, `tree`, `rm`, `cat` | `home/shell.nix:10-15` |
| History settings | not explicit | — |
| AI in shell | none | — |
| `nix develop` shell | Bash, no user prompt | Nix behaviour |
| Completion extras | only HM defaults | — |

## Problems

1. **Two prompt systems.** `programs.zsh.oh-my-zsh` loads the `agnoster`
   theme, then Starship initialises and replaces the prompt. Depending on
   load order and rebuild, one wins; the other wastes startup time. Pick one.
2. **`z` is defined twice.** The OMZ `z` plugin and `zoxide --cmd cd` both
   maintain a directory database. The plugin and zoxide can disagree, and one
   may silently shadow the other. Remove the OMZ `z` plugin; use zoxide.
3. **The API key is global.** Every interactive shell exports
   `DEEPSEEK_API_KEY`, so Chrome, Steam, Zoom, games, and any agent inherit it.
   This is the single worst shell issue; see [`security.md`](security.md).
4. **Starship's time module is invisible.** `time.disabled = false` is set,
   but the `format` string does not contain `$time`, so nothing is rendered.
   Either add `$time` or remove the module.
5. **`rust.disabled = true` hides Rust information** even though
   `rust-analyzer` is installed. If Rust work is intentional, enable it;
   otherwise leave it and document why.
6. **`nix develop` does not load this configuration.** Nix starts an
   interactive Bash with its own rc file; it does not source `~/.zshrc` or the
   Home Manager zsh init. The result is a plain prompt, no aliases, no
   autosuggestions, no `direnv` hook, and no AI helper. This is Nix behaviour,
   not a broken Starship install.
7. **No history policy.** zsh's default history is small and not shared
   between sessions. Set `HISTSIZE`, `SAVEHIST`, `SHARE_HISTORY`,
   `HIST_IGNORE_SPACE`, and `HIST_REDUCE_BLANKS`.
8. **No completion beyond the defaults.** Nix, `git`, `just`, `uv`, and
   devshell tools have useful completions that are not guaranteed to be on
   `fpath`.
9. **`oh-my-zsh` is installed twice.** `home/packages.nix:8` installs the
   package and `programs.zsh.oh-my-zsh.enable` installs/uses it again. Remove
   the package line if the module stays.
10. **`cat = bat` can surprise.** `bat` is fine interactively, but it may page
    or add decorations. Use `bat --paging=never --style=plain` for a `cat`
    replacement, or keep the real `cat` and use `bat` explicitly.
11. **`MODELS` uses a literal `$HOME`.** It happens to expand when the shell
    starts, but it is clearer to build it from
    `config.home.homeDirectory`.
12. **`programs.bash.enable` is needed** for `nix develop` and recovery. Keep
    it even after moving the interactive shell to zsh.

## Target design

### One prompt: Starship

Keep `programs.starship`, remove the OMZ theme. Either:

- disable Oh My Zsh entirely and use small plugins directly; or
- keep OMZ for `git`/`sudo`/`colored-man-pages` but set
  `oh-my-zsh.theme = ""` and remove the `z` plugin.

The first option is cleaner and faster; the second is a smaller change. Do
not keep two prompt systems.

Suggested Starship fixes:

```nix
programs.starship = {
  enable = true;
  settings = {
    format = "$shlvl$shell$username$hostname$nix_shell$git_branch$git_commit$git_state$git_status$directory$jobs$cmd_duration$time$character";
    add_newline = false;
    command_timeout = 1000;          # ms; avoid stalls in huge repos
    time = {
      disabled = false;
      time_format = "%H:%M:%S";
      format = "[$time]($style) ";
    };
    # Remove this if you do Rust work:
    rust.disabled = true;
  };
};
```

If `command_timeout` makes the prompt drop slow modules, that is preferable
to a laggy shell. Measure startup with `hyperfine 'zsh -i -c exit'`.

### zsh history

```nix
programs.zsh = {
  enable = true;
  history = {
    size = 100000;
    save = 100000;
    share = true;
    ignoreSpace = true;
    ignoreDups = true;
    ignoreAllDups = true;
    expireDuplicatesFirst = true;
    path = "${config.xdg.dataHome}/zsh/history";
  };
  setOptions = [
    "AUTO_CD"
    "EXTENDED_GLOB"
    "INTERACTIVE_COMMENTS"
    "NO_BEEP"
  ];
};
```

`HIST_IGNORE_SPACE` lets you prefix a command with a space to keep it out of
history. That is not a security boundary; use it only as a convenience.

### zoxide

Choose one behaviour:

```nix
programs.zoxide = {
  enable = true;
  enableZshIntegration = true;
  options = ["--cmd cd"];   # cd uses the zoxide database; `z` is not defined
};
```

or remove `--cmd cd` to keep `cd` normal and use `z`. Do not also enable the
OMZ `z` plugin. If you keep `--cmd cd`, document that `cd` now jumps by
freelist and `builtin cd` is the plain directory change.

### `nix develop` and `nix-shell`

The reliable fix is to start zsh inside the devshell:

```zsh
# in programs.zsh.initContent
nd() {
  nix develop "$@" --command zsh
}
```

Then `nd`, `nd .`, `nd .#devShell` all open zsh with `~/.zshrc`, Starship,
zoxide, Aliases, and autosuggestions. The devshell environment variables are
still set by Nix. If zsh is not on the devshell `PATH`, use
`${pkgs.zsh}/bin/zsh` or add `pkgs.zsh` to the devShell.

The alternative is `direnv`:

```sh
# .envrc in a project
use flake
```

```sh
direnv allow
```

With `nix-direnv`, entering the directory loads the devshell into the current
zsh; Starship and all shell features stay. This is the best long-term setup
for projects you enter repeatedly. The tradeoff is that every project needs
an `.envrc`, and `direnv` must be allowed once per file.

Do not try to make `nix develop` source `~/.zshrc` by editing `BASH_ENV` or
`--rcfile`; it is fragile and breaks when Nix changes its shell wrapper.

### Completions inside devshells

- Add `pkgs.zsh-completions` to Home Manager and ensure its
  `share/zsh/site-functions` is on `fpath`.
- Add `pkgs.zsh` and any tool-specific completion package to a devShell if
  the tool is only available there.
- Verify with `echo $fpath` and `compdef` / `which _nix`.
- For Bash fallback, add `pkgs.bash-completion` and `enableCompletion` where
  HM supports it.
- `fzf-tab` gives a fuzzy completion menu; it is optional and adds startup
  cost. `carapace` is a larger, multi-shell completion bridge; only add it if
  you want one completion source for many CLIs.

### Inline AI without a second key consumer

Use OpenCode's non-interactive `run` command for shell helpers. The provider
credential stays in `~/.local/share/opencode/auth.json` (0600); no environment
variable is exported and no second CLI needs its own copy of the key:

```zsh
ai() {
  opencode run "$*"
}

ai-cmd() {
  local prompt out
  prompt="Return only a single POSIX shell command, no markdown, for: $*"
  out="$(opencode run "$prompt")" || return
  print -z -- "$out"      # put it on the command line; do not execute
}
```

`print -z` is deliberately used instead of executing the model output. Review
the command and press Enter. Verify the exact flags and output mode with
`opencode run --help`; if the normal output includes status lines, use a JSON
or quiet mode so `ai-cmd` receives only the command.

`aichat` and `mods` are good tools, but each is a **second consumer of the
key**. The locked decision is that only OpenCode holds `DEEPSEEK_API_KEY`. If
you later approve another client, give it a separate 0600 secret and wrapper;
do not re-export the key globally. A `mods` pipe example, for reference only:

```sh
git diff | mods "review this diff for bugs"
```

Do not put the key in `~/.zshrc`, `home.sessionVariables`, or a Home Manager
`home.file`; all of those are inherited by every child process or copied to
the world-readable Nix store. See [`security.md`](security.md).

### Atuin and history search

`atuin` replaces Ctrl-R with a searchable SQLite history and optional
end-to-end encrypted sync.

```nix
programs.atuin = {
  enable = true;
  enableZshIntegration = true;
  settings = {
    auto_sync = false;          # local-only until you decide to sync
    search_mode = "fuzzy";
    filter_mode = "global";
    history_filter = [
      "^export .*KEY=.*"
      "^export .*TOKEN=.*"
      "^opencode auth"
    ];
  };
};
```

Then:

```sh
atuin import auto     # import existing zsh history
atuin search --limit 20
atuin stats
```

`history_filter` is a safety net, not a guarantee. Atuin records command
context; review its privacy settings before enabling sync. If you use sync,
the encryption key is another secret to back up.

### Efficiency and convenience

Add these as packages/functions, not as a wall of aliases:

| Tool | Use |
|---|---|
| `zoxide` | `z project` jumps to frecent directories |
| `fzf` | `Ctrl-T` files, `Ctrl-R` history (or Atuin), `Alt-C` directories |
| `fd` | `fd pattern` is faster and friendlier than `find` |
| `ripgrep` | `rg pattern` for content search |
| `bat` | `bat file` for syntax-highlighted reading |
| `eza` | `eza -l --git` for listings |
| `delta` | `git diff` pager with side-by-side diffs |
| `direnv` | per-project devshells without manual `nix develop` |
| `nh` | `nh os switch`, `nh os boot`, `nh clean` (see [`tools.md`](tools.md)) |
| `just` | project commands (`just test`, `just fmt`) |
| `uv` | Python venvs and `uvx` tools (see [`tools.md`](tools.md)) |

Useful aliases/functions:

```zsh
alias ll='eza -l --group-directories-first --git'
alias la='eza -la --group-directories-first --git'
alias lt='eza -T --level=2'
alias gs='git status --short --branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gc='git commit'
alias nrs='nh os switch'
alias nrb='nh os boot'
alias nrt='nh os test'
alias nd='nix develop --command zsh'
```

Do not alias `sudo` to something that hides the prompt; the OMZ `sudo`
plugin's double-Esc behaviour is convenient but optional.

### Startup performance

Measure before removing features:

```sh
hyperfine --warmup 3 'zsh -i -c exit'
zsh -i -c 'zmodload zsh/zprof; zprof' | head -30
```

Common costs: Oh My Zsh, `nvm`/`pyenv`-style shims, completion caches, and
large git repositories in the prompt. `starship` itself is fast; a slow
`git_status` in a huge repo is the usual cause. `command_timeout` bounds it.

## Tasks

- [ ] Remove the OMZ `agnoster` theme (or disable OMZ entirely).
- [ ] Remove the OMZ `z` plugin; keep one zoxide behaviour.
- [ ] Remove the global `DEEPSEEK_API_KEY` export.
- [ ] Move provider credentials into `opencode auth login` / `auth.json`; delete the old `0600` key file.
- [ ] Add `$time` to the Starship format or remove the time module.
- [ ] Set explicit zsh history options.
- [ ] Add `nd()` / document `nix develop --command zsh`.
- [ ] Add `.envrc` + `use flake` to the NixOS repo and at least one project.
- [ ] Add `zsh-completions`; verify `fpath`.
- [ ] Add the `ai`/`ai-cmd` functions using `opencode run`.
- [ ] Add `atuin` with local-only sync disabled initially.
- [ ] Remove the duplicate `oh-my-zsh` package.
- [ ] Benchmark startup before/after.
- [ ] Keep `programs.bash.enable = true` for recovery and devshells.

## Verification

```sh
zsh -i -c 'echo "PROMPT=$PROMPT"'
zsh -i -c 'echo "DEEPSEEK=${DEEPSEEK_API_KEY:-unset}"'   # must be unset
zsh -i -c 'typeset -f nd >/dev/null && echo nd-ok'
nix develop --command zsh -c 'echo shell=$0; echo nix_shell=$IN_NIX_SHELL; starship --version'
direnv status
atuin doctor
atuin search --limit 5
hyperfine --warmup 3 'zsh -i -c exit'
```

`nix develop --command zsh -c ...` is non-interactive; it verifies that zsh
and Starship are reachable, not that the prompt renders. For a visual check,
run `nix develop --command zsh` and confirm the prompt shows the Nix shell
segment.

## Open questions

- Keep Oh My Zsh for its git aliases, or replace it with a few explicit
  aliases?
- `zoxide --cmd cd` (hijack `cd`) or plain `z`?
- Which OpenCode provider/model and agent should `opencode run` use by default?
- Is Atuin sync wanted, or local history only?
- Should `direnv` auto-load every project, or only when you add `.envrc`?
- Do you want `fzf-tab` and `carapace`, or are native completions enough?