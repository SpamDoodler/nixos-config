# Editor snippets

Custom LuaSnip definitions live in `lua/snippets/{cpp,python,latex}.lua`.
Home Manager deploys them under `lua/nixsama/snippets`; the namespaced
`plugins/snippets.lua` module lazy-loads them by filetype. Neovim's `tex`
filetype also uses the `latex` collection. There are no Go definitions.

## Usage

Type a trigger, then use completion (`Ctrl-Space` if necessary), select the
snippet and press Enter. Tab/Shift-Tab move through fields after expansion.
With no completion popup, Tab also expands an available snippet; with the popup
visible it retains the existing completion-selection behavior. No automatic
expansion or competing snippet keymaps are enabled.

Repeated fields are linked: changing the variable in `fori`, class name in
`cls`, or environment in `beg` updates its other occurrences.

| Filetype | Triggers |
|---|---|
| C++ | `inc` header; `main`; `fn` function; `fori` indexed loop; `forr` range loop; `iff` conditional; `cls` class; `struct`; `cout`; `cin` |
| Python | `def`; `cls`; `main`; `for`; `enum` enumerate; `with` text-file context manager; `try`; `test`; `dclass` dataclass; `prop` property |
| LaTeX (`tex`) | `beg` environment; `sec`; `ssec`; `eq`; `ali` align; `thm`; `lem`; `proof`; `frac`; `sum`; `int`; `ref`; `cite` |

## Conventions and requirements

- Definitions return snippets through the supported Lua loader. Configuration
  belongs in `plugins/snippets.lua`, mappings in `plugins/completion.lua`.
  Do not add global helpers or another Tab mapping to a definition file.
- Placeholder text is a starting template, not finished code. Replace conditions,
  bodies, argument lists, and test expectations before using the result.
- C++ templates use qualified standard-library names, not `using namespace std`.
  Add required headers: `<iostream>` for I/O, `<cstddef>` for `std::size_t`.
- Python `dclass` includes an import and is intended for module scope. Move or
  merge the import if dataclasses are already imported. `with` defaults to
  reading UTF-8 text; change the mode/encoding for other uses.
- LaTeX `ali` needs `amsmath`; `proof` normally needs `amsthm`. The `theorem`
  and `lemma` environments must be defined in the preamble (e.g. `\newtheorem`).
  `frac`, `sum`, and `int` are math-mode fragments, not math delimiters.
  Replace example equation content and give labels/citations real unique keys.
- Custom definitions load only on the relevant filetype. To edit templates,
  change the source files and rebuild the managed configuration. Avoid changing
  store symlinks or adding a second imperative snippet installation.

## Verification

The initial implementation was tested in an isolated headless candidate editor:
all 33 snippets expanded, `tex` resolved the LaTeX collection, fields were
jumpable, and linked environment names updated. Python expansions passed AST
parsing, representative C++ output passed a C++17 syntax-only compilation, and
LaTeX expansions compiled in a minimal document with the required packages and
environments. This validates templates, not the code/proofs subsequently written
into their placeholders. Interactive completion selection remains a manual check.
