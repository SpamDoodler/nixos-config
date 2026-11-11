"""Prepare an explicitly approved UTF-8 corpus for Graphify; no extraction/API calls."""

import argparse
import hashlib
import json
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def git(root, *args):
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, text=True, check=False
    )
    return result.stdout.strip() if result.returncode == 0 else None


def prepare(root, selection, out, max_file=2 * 1024**2, max_total=10 * 1024**2):
    root = Path(root).resolve(strict=True)
    out = Path(out).absolute()
    relative_out = out.relative_to(root)
    if relative_out.parts[0] != "graphify-out" or len(relative_out.parts) < 2:
        raise ValueError("output must be a new directory below PROJECT/graphify-out/")
    if ".." in relative_out.parts:
        raise ValueError("output traversal is forbidden")
    for ancestor in [out, *out.parents]:
        if ancestor.is_symlink():
            raise ValueError("output symlinks are forbidden")
    if out.exists():
        raise ValueError("output already exists; choose a fresh build directory")
    if not isinstance(selection, list) or not selection:
        raise ValueError("selection must be a nonempty array of path/mode records")
    blocked = {".git", ".opencode-tmp", "graphify-out", "node_modules", "__pycache__"}
    records, payloads, targets, sources = [], [], set(), set()
    total = 0
    for entry in selection:
        if not isinstance(entry, dict) or set(entry) != {"path", "mode"}:
            raise ValueError("each selection needs exactly path and mode")
        rel = Path(entry["path"])
        if rel.is_absolute() or not rel.parts or ".." in rel.parts:
            raise ValueError("sources must be project-relative files without traversal")
        if any(p in blocked or p.startswith(".env") or
               "secret" in p.lower() or "credential" in p.lower() or
               p.lower() in {"id_rsa", "id_ed25519"} for p in rel.parts):
            raise ValueError(f"excluded source path: {rel}")
        if entry["mode"] not in {"copy", "text"}:
            raise ValueError("mode must be copy or text")
        source = root / rel
        current = root
        for part in rel.parts:
            current /= part
            if current.is_symlink():
                raise ValueError(f"source symlink forbidden: {rel}")
        if not source.is_file():
            raise ValueError(f"source is not a regular file: {rel}")
        if source.stat().st_size > max_file:
            raise ValueError(f"file exceeds approved byte limit: {rel}")
        data = source.read_bytes()
        data.decode("utf-8")  # Fail closed on binary or non-UTF-8 source.
        if b"\x00" in data or len(data) > max_file:
            raise ValueError(f"binary or oversized source: {rel}")
        total += len(data)
        if total > max_total:
            raise ValueError("selection exceeds approved total byte limit")
        target = Path(str(rel) + ".md") if entry["mode"] == "text" else rel
        if target in targets or rel in sources:
            raise ValueError(f"duplicate source or prepared-path collision: {rel}")
        targets.add(target)
        sources.add(rel)
        records.append({"source": rel.as_posix(), "prepared": target.as_posix(),
                        "mode": entry["mode"], "line_offset": 0,
                        "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)})
        payloads.append((target, data))
    # Detect file/directory collisions before writing any output.
    if any(parent in targets for p in targets for parent in p.parents):
        raise ValueError("prepared file/directory collision")
    provenance = {"status": "prepared", "project_root": str(root),
                  "scan_root": str(out / "input"),
                  "prepared_at": datetime.now(timezone.utc).isoformat(),
                  "revision": git(root, "rev-parse", "HEAD"),
                  "dirty": None, "inputs": records, "total_bytes": total}
    status = git(root, "status", "--porcelain")
    provenance["dirty"] = None if status is None else bool(status)
    out.mkdir(parents=True, exist_ok=False)
    for target, data in payloads:
        path = out / "input" / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
    (out / "preparation.json").write_text(json.dumps(provenance, indent=2) + "\n")
    return provenance


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--selection", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--max-file-bytes", type=int, default=2 * 1024**2)
    parser.add_argument("--max-total-bytes", type=int, default=10 * 1024**2)
    args = parser.parse_args()
    try:
        result = prepare(args.root, json.loads(args.selection.read_text()), args.out,
                         args.max_file_bytes, args.max_total_bytes)
    except (ValueError, OSError, TypeError) as exc:
        parser.exit(1, f"graphify-prepare: {exc}\n")
    print(f"Prepared {len(result['inputs'])} files, {result['total_bytes']} bytes; no graph built.")


if __name__ == "__main__":
    main()
