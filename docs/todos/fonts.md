# Fonts

Priority: **P1** for the missing-glyph bugs, **P2** for the cleanup. The
current list installs several competing CJK families, a non-font package, and
no symbol font for the Nerd Font icons used by Waybar.

## Current state

`fonts/fonts.nix`:

```nix
fonts = {
  enableDefaultPackages = true;
  packages = with pkgs; [
    nerd-fonts.fira-code
    sarasa-gothic
    corefonts
    cascadia-code
    fira-code
    dejavu_fonts
    noto-fonts
    noto-fonts-cjk-sans
    source-han-sans
    source-han-serif
    source-code-pro
    noto-fonts-color-emoji
    noto-fonts          # duplicate
    pango               # not a font
    hack-font
    jetbrains-mono
    lmodern
    lmmath
    (pkgs.stdenv.mkDerivation { name = "BrownPro"; ... })
  ];
  fontconfig.defaultFonts = {
    monospace = ["Sarasa Mono SC" "Noto Sans Mono CJK SC"];
    sansSerif = ["Noto Sans CJK SC" "Source Code Pro"];
    serif = ["Noto Serif CJK SC" "Source Code Pro"];
  };
};
```

Live checks:

```text
fc-match monospace              -> Sarasa Mono SC
fc-match 'Noto Sans CJK SC'     -> Noto Sans CJK SC
fc-match 'Noto Serif CJK SC'    -> Noto Serif CJK SC
fc-match 'Symbols Nerd Font'    -> Noto Sans CJK SC   (fallback: font is missing)
```

The last line is the bug behind missing/incorrect Waybar icons: no Nerd
symbols font is installed, so unknown glyphs fall back to a CJK font or a box.

## Problems

1. **`pango` is not a font.** It is a text-layout library. Putting it in
   `fonts.packages` makes fontconfig scan a package with no fonts and pulls a
   large closure for no reason. Remove it.
2. **`noto-fonts` is listed twice** (lines 11 and 17). Remove one.
3. **Source Han and Noto CJK overlap.** `source-han-sans`/`source-han-serif`
   and `noto-fonts-cjk-sans`/`noto-fonts-cjk-serif` are the same Adobe/Google
   CJK design under two names. Installing both duplicates glyphs, increases
   the store size, and makes `fc-match` results depend on ordering.
4. **The live system already has Noto Serif CJK SC**, even though this file
   does not list `noto-fonts-cjk-serif`. `enableDefaultPackages = true` is
   already providing some of these; explicit duplicates should be removed
   after checking `fonts.packages`.
5. **`Source Code Pro` is used as a sans/serif fallback.** It is a monospace
   design. Use `Noto Sans`/`DejaVu Sans` and `Noto Serif`/`DejaVu Serif`.
6. **No Nerd symbol font.** Waybar's formats use glyphs such as ``,
   ``, ``, ``, ``. Neither Sarasa Mono SC nor Noto CJK is guaranteed to
   contain them. Add `nerd-fonts.symbols-only` and put `Symbols Nerd Font` in
   the fallback list; or use a Nerd-patched terminal font.
7. **Too many monospace families.** Fira Code, FiraCode Nerd Font, Cascadia
   Code, Hack, JetBrains Mono, Source Code Pro, Sarasa Gothic, and Noto Sans
   Mono CJK all compete. Pick two: one CJK-capable terminal font (Sarasa
   Mono SC) and one Latin Nerd font (JetBrainsMono Nerd Font or FiraCode Nerd
   Font). Remove the rest unless a specific app requires one.
8. **BrownPro is a hand-rolled derivation.** It copies only `*.ttf` and
   ignores the `.otf`, `.woff`, and `.eot` files in `fonts/BrownPro`. The
   `cp -r $src/*.ttf` also fails if no match. If BrownPro is not used, delete
   the derivation and the directory; if it is, install the TTF/OTF files with
   `install -Dm644` and a proper `meta`.
9. **`corefonts` is proprietary Microsoft compatibility.** Keep only if
   LibreOffice/Steam/specific documents need Arial/Times; otherwise remove.
   It requires `allowUnfree`.
10. **`lmodern`/`lmmath` duplicate TeX Live fonts.** Useful only if
    non-TeX applications need them through fontconfig. `texliveFull` already
    provides them to LaTeX.
11. **The Nvim GUI font is Cascadia Code**, while terminals use Sarasa. If
    Cascadia is removed, update `home/nvim/lua/setup/gui.lua:2`.
12. **Waybar's `font-family` is only `Sarasa Mono SC`.** Even with a symbol
    font installed, Pango fallback may not select it for private-use glyphs.
    List the fallback explicitly.

## Answer: which Chinese font?

For this machine, the best default set is:

| Role | Font | Why |
|---|---|---|
| UI / sans | **Noto Sans CJK SC** | Clean, neutral, complete Simplified Chinese coverage, good hinting, already used by Sway and the desktop |
| Serif / prose | **Noto Serif CJK SC** | Matches Noto Sans, comfortable for long text |
| Terminal / code | **Sarasa Mono SC** | Monospace CJK + Latin, already used by Ghostty, Alacritty, and Waybar |
| Optional handwriting | **LXGW WenKai** | Distinctive, warm prose font; not a UI default |

Source Han Sans/Serif are the Adobe-branded upstream of Noto CJK. There is no
visual reason to install both. Keep **Noto CJK** because it is already the
desktop default and has the broadest integration. Remove
`source-han-sans` and `source-han-serif` unless you specifically need Adobe's
release for a document.

If you want a more distinctive look, use LXGW WenKai for Markdown/LaTeX prose
and keep Noto Sans CJK SC for the UI. Do not make a handwriting font the
global sans-serif default; small UI text becomes harder to read.

## Target configuration

Keep `enableDefaultPackages = true` for the base set, then add only what is
missing:

```nix
fonts = {
  enableDefaultPackages = true;

  packages = with pkgs; [
    # CJK UI/prose (choose Noto, not both Noto and Source Han)
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    # Terminal/CJK monospace
    sarasa-gothic
    # Nerd Font icons for Waybar/terminals
    nerd-fonts.symbols-only
    # One Latin Nerd font, if you want a non-CJK option
    nerd-fonts.jetbrains-mono
    # Emoji
    noto-fonts-color-emoji
    # Optional compatibility / TeX
    corefonts          # only if needed
    lmodern
    lmmath
  ];

  fontconfig.defaultFonts = {
    monospace = [
      "Sarasa Mono SC"
      "JetBrainsMono Nerd Font"
      "Noto Sans Mono CJK SC"
    ];
    sansSerif = [
      "Noto Sans CJK SC"
      "Noto Sans"
      "DejaVu Sans"
    ];
    serif = [
      "Noto Serif CJK SC"
      "Noto Serif"
      "DejaVu Serif"
    ];
    # Verify this category exists in the pinned NixOS module.
    emoji = ["Noto Color Emoji"];
  };
};
```

Notes:

- `nerd-fonts.symbols-only` provides the icon glyphs without another full
  text family. Verify the family name with
  `fc-list | grep -i 'Symbols Nerd'`; it is usually `Symbols Nerd Font` and
  `Symbols Nerd Font Mono`.
- If you prefer Fira Code, use `nerd-fonts.fira-code` and remove
  `nerd-fonts.jetbrains-mono`; do not install both the plain and Nerd
  variants.
- If `enableDefaultPackages` already provides `noto-fonts`,
  `noto-fonts-cjk-sans`, `noto-fonts-cjk-serif`, `dejavu_fonts`, or
  `noto-fonts-color-emoji`, remove the explicit duplicates. Check the actual
  list rather than guessing:
  `nix eval .#nixosConfigurations.NixSama.config.fonts.packages --apply 'map (p: p.name)'`.
- Do not add `pango`; it is not a font.
- BrownPro: delete it if unused. If kept, use:
  ```nix
  (pkgs.stdenv.mkDerivation {
    pname = "brown-pro";
    version = "1.0";
    src = ./BrownPro;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      find $src -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) \
        -exec install -Dm644 {} $out/share/fonts/truetype/ \;
    '';
  })
  ```

## Application-specific fixes

### Waybar

```css
* {
  font-family: "Sarasa Mono SC", "Symbols Nerd Font", sans-serif;
}
```

If the icons still fail, run `fc-match -s 'Symbols Nerd Font' | head` and
confirm the font is installed. Prefer a Nerd-patched font for the whole bar
if you want consistent icon metrics.

### Ghostty / Alacritty

Ghostty supports a fallback list:

```nix
font-family = ["Sarasa Mono SC" "Symbols Nerd Font Mono"];
```

Alacritty takes one family at a time; its fontconfig fallback will find the
symbol font if it is installed. If icons remain broken, switch Alacritty to a
Nerd-patched family such as `JetBrainsMono Nerd Font`.

### Neovim GUI

`home/nvim/lua/setup/gui.lua:2` uses `Cascadia Code`. Either keep Cascadia
(and remove the plain `cascadia-code` only if another package provides it) or
change it to `Sarasa Mono SC` / `JetBrainsMono Nerd Font`. This is part of the
deferred Neovim work; do not change it in the font pass unless you also verify
the GUI.

### Sway

`home/sway/sway.nix:41` uses `Noto Sans CJK SC`; that is consistent with the
target. Do not touch Sway until its separate test.

## Tasks

- [ ] Remove `pango` from `fonts.packages`.
- [ ] Remove the duplicate `noto-fonts`.
- [ ] Choose Noto CJK **or** Source Han, not both; remove the other.
- [ ] Add `noto-fonts-cjk-serif` if it is not already provided.
- [ ] Add `nerd-fonts.symbols-only`.
- [ ] Add `Symbols Nerd Font` to Waybar's font stack.
- [ ] Replace `Source Code Pro` sans/serif fallbacks with Noto/DejaVu.
- [ ] Remove unused monospace families; keep Sarasa + one Latin Nerd font.
- [ ] Delete or fix the BrownPro derivation.
- [ ] Decide whether `corefonts` is needed.
- [ ] Verify `enableDefaultPackages` duplicates before removing them.
- [ ] Confirm `fc-match` and `fc-list :lang=zh` results.
- [ ] Check Waybar, Ghostty, Alacritty, Sway, and Nvim GUI after the rebuild.

## Verification

```sh
fc-match monospace
fc-match sans-serif
fc-match serif
fc-match 'Symbols Nerd Font'
fc-list :lang=zh family | sort -u | head -30
fc-list | grep -iE 'sarasa|symbols nerd|noto sans cjk|noto serif cjk' | head
fc-cache -fv >/dev/null && echo cache-ok
```

Visual checks:

1. Waybar: all icons render, no boxes.
2. Ghostty/Alacritty: Chinese text and Nerd icons render in the same line.
3. Sway: title bars and UI text are readable.
4. LibreOffice/Chrome: Chinese and Latin text use consistent families.
5. Emoji: color emoji render (not monochrome fallback).

## Open questions

- Do you actually use BrownPro? If not, remove it and `fonts/BrownPro/`.
- Do you need `corefonts` for any document or game?
- Is Cascadia Code still wanted for the Nvim GUI, or should it match the
  terminal?
- Do you prefer Noto Sans CJK SC or LXGW WenKai for prose?
- Should Waybar use a Nerd-patched Sarasa variant instead of a fallback
  symbol font?