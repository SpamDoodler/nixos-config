# AI + SuperCollider

This is the first shared workspace for exploring AI-assisted sound design with
SuperCollider. Each session keeps the prompt, source code, and rendered result
together so it can later be published on the website.

## Start

From the repository root:

```sh
nix develop .#ai-supercollider
pw-jack sclang projects/ai-supercollider/sessions/01-first-sound.scd
```

The first session boots a local synth and plays a short generative texture.
Open it in SuperCollider IDE or run the file with `sclang` when the audio
server is available.

## PipeWire / JACK

The system provides `pw-jack` instead of setting `LD_LIBRARY_PATH` globally.
Use it for JACK clients so that their child processes inherit PipeWire's JACK
libraries. The development shell also includes this wrapper.

```sh
pw-jack scide       # SuperCollider IDE
pw-jack nvim        # Neovim/scnvim session that launches sclang and scsynth
```

Ordinary ALSA/PulseAudio applications do not need the wrapper. After switching
from the old global JACK setting, log out and back in: existing shells and user
processes can retain the old `LD_LIBRARY_PATH`. Test server boot, sound output,
and stopping playback before considering this audio migration runtime-verified.

## Workspace

- `prompts/` contains AI prompts and revisions.
- `sessions/` contains executable SuperCollider sketches.
- `renders/` contains exported audio and images.
- `website/` contains publishable notes for the site.
