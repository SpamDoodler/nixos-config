# LaTeX and Markdown: LTeX+

LTeX+ supplies spelling and grammar diagnostics in `tex`, `plaintex`, and
`markdown` buffers. The Nix-managed `ltex-ls-plus` includes its Java runtime and
LanguageTool dictionaries; no Mason, runtime language-server downloads, account,
AI model, or hosted LanguageTool endpoint is used. First attachment can take a
few seconds and uses a Java process. A project dev shell is not required for it.

texlab and ChkTeX remain enabled for TeX syntax/reference/source-lint diagnostics.
LTeX+ owns prose spelling/grammar; built-in spelling is disabled in windows
displaying the buffer when it attaches. Existing manual formatters are unchanged.

## Corrections

- Gutter warning signs, mouse-hover popups over the gutter **or flagged text**,
  and `,e` show messages. Mouse hover works in Normal/Insert/Visual mode without
  moving the editing cursor; the popup stays open when the pointer enters it.
  Terminal mouse-move reporting is required; `,e` is the keyboard fallback.
- Put the **editing cursor on the diagnostic line** and press **F4**. This
  requests actions for the whole line; mouse hover alone does not select a line.
  In Visual mode, F4 requests actions for the selected range. `,ca` remains an alias.
- Select a suggested replacement, **Add to dictionary**, **Hide false positive**,
  or **Disable rule**. Nothing is automatically fixed or saved to the source file.
- For one flagged word, put the cursor **inside that word** and press **`zg`**
  (or run `:LtexAddWord`) to add it directly to the project dictionary.
  `:LtexIgnore` directly hides the false positive for that rule and sentence.
  These direct actions update only the saved project choices, not source text.
- Prefer adding a legitimate technical term or hiding a sentence-specific false
  positive over disabling an entire rule. Disabling applies to the project and
  selected natural language, not only the current occurrence.
- Dictionary additions, disabled rules, and hidden false positives persist per
  LSP project root in `stdpath("data")/nixsama/ltex/<sha256-of-root>.json` (normally
  `~/.local/share/nvim/nixsama/ltex/`). These writable files are outside the Nix
  store, are not uploaded, and may include sentence text. For standalone files
  without a Git root the startup working directory is the scope. Moving a
  project changes its key. Concurrent editors should not change these lists at
  the same instant. Close Neovim, edit/remove the relevant JSON, and reopen to
  undo saved exceptions. `:lua print(vim.fn.stdpath("data"))` locates the data root.

Ordinary replacement edits are native LSP code actions. The small
`lua/plugins/ltex.lua` module implements LTeX+'s three client-side persistence
commands, so those menu items work too.

## Language, math, and custom markup

The default is **US English** (`en-US`); extra picky style rules are off. Choose
another language per document with a supported magic comment:

```tex
% LTeX: language=en-GB
```

```markdown
<!-- LTeX: language=de-DE -->
```

Standard LaTeX math/verbatim regions and Markdown inline/fenced code and dollar
math are handled by the server's markup parser rather than spellchecked as prose.
These cases are covered by the integration test. Custom macros
and nonstandard math delimiters can still need tuning; no parser can infer every
project's macro semantics. Use `ltex.latex.commands`, `ltex.latex.environments`,
and `ltex.markdown.nodes` in the native server configuration for such exceptions.
Avoid declaring an entire prose-containing macro/environment ignored merely to
silence one warning. This setup does **not** automatically load VS Code settings.

Reference: <https://ltex-plus.github.io/ltex-plus/settings.html> and
<https://ltex-plus.github.io/ltex-plus/advanced-usage.html>.

## Validation

With the candidate config/plugin pack loaded, an isolated `XDG_DATA_HOME`, and
`TMPDIR` set:

```sh
nvim --headless -c 'luafile tests/neovim-ltex.lua'
```

This uses real local-server diagnostics, tests spelling/grammar and markup
exclusion, applies a correction only to a disposable unsaved buffer, and checks
project-scoped persistence for all three exception actions. It makes no paid
inference request and does not modify user dictionaries.
