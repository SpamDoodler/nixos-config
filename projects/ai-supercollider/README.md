# AI + SuperCollider

This is the first shared workspace for exploring AI-assisted sound design with
SuperCollider. Each session keeps the prompt, source code, and rendered result
together so it can later be published on the website.

## Start

From the repository root:

```sh
nix develop .#ai-supercollider
sclang projects/ai-supercollider/sessions/01-first-sound.scd
```

The first session boots a local synth and plays a short generative texture.
Open it in SuperCollider IDE or run the file with `sclang` when the audio
server is available.

## Workspace

- `prompts/` contains AI prompts and revisions.
- `sessions/` contains executable SuperCollider sketches.
- `renders/` contains exported audio and images.
- `website/` contains publishable notes for the site.
