"""Offline tests: run with python3 tests/test_graphify_prepare.py."""

import hashlib
import json
import os
from pathlib import Path
import runpy
import tempfile
import unittest

prepare = runpy.run_path(
    str(Path(__file__).resolve().parents[1] / "home/opencode/graphify-prepare.py")
)["prepare"]


class PreparationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=os.environ.get("TMPDIR"))
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.out = self.root / "graphify-out/build-1"

    def write(self, name, data):
        p = self.root / name
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_bytes(data)

    def test_verbatim_tex_and_mixed_sources(self):
        tex = b"\\newcommand{\\R}{\\mathbb{R}}\r\n\\label{claim}\n$x \\in \\R$"
        self.write("paper/main.tex", tex)
        self.write("check.sage", b"assert 2^3 == 8\n")
        self.write("notes.md", b"# Questions\n")
        self.write("solve.py", b"def solve():\n    return 1\n")
        selection = [{"path": p, "mode": m} for p, m in
                     [("paper/main.tex", "text"), ("check.sage", "text"),
                      ("notes.md", "copy"), ("solve.py", "copy")]]
        result = prepare(self.root, selection, self.out)
        self.assertEqual((self.out / "input/paper/main.tex.md").read_bytes(), tex)
        self.assertEqual(result["inputs"][0]["sha256"], hashlib.sha256(tex).hexdigest())
        self.assertEqual(result["inputs"][0]["line_offset"], 0)
        self.assertEqual(result["status"], "prepared")
        self.assertEqual(len(list((self.out / "input").rglob("*.md"))), 3)
        self.assertEqual(json.loads((self.out / "preparation.json").read_text()), result)

    def test_forbidden_paths(self):
        for name in ("../escape.tex", "/absolute.tex", ".env", "secrets/a.tex",
                     ".opencode-tmp/a.tex", "graphify-out/old.md"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                prepare(self.root, [{"path": name, "mode": "text"}], self.out)
        self.assertFalse(self.out.exists())

    def test_symlinks_and_binary(self):
        self.write("real.tex", b"text")
        (self.root / "linked.tex").symlink_to(self.root / "real.tex")
        self.write("binary.tex", b"text\x00binary")
        self.write("invalid.tex", b"\xff")
        for name in ("linked.tex", "binary.tex", "invalid.tex"):
            with self.subTest(name=name), self.assertRaises(ValueError):
                prepare(self.root, [{"path": name, "mode": "text"}], self.out)
        self.assertFalse(self.out.exists())

    def test_collision_and_limits(self):
        self.write("a.tex", b"1234")
        self.write("a.tex.md", b"duplicate target")
        selection = [{"path": "a.tex", "mode": "text"},
                     {"path": "a.tex.md", "mode": "copy"}]
        with self.assertRaises(ValueError):
            prepare(self.root, selection, self.out)
        for limits in ({"max_file": 2}, {"max_total": 2}):
            with self.assertRaises(ValueError):
                prepare(self.root, selection[:1], self.out, **limits)
        self.assertFalse(self.out.exists())

    def test_no_overwrite_or_output_escape(self):
        self.write("a.tex", b"text")
        selection = [{"path": "a.tex", "mode": "text"}]
        for out in (self.root / "elsewhere", self.root / "graphify-out/../escape"):
            with self.assertRaises(ValueError):
                prepare(self.root, selection, out)
        prepare(self.root, selection, self.out)
        with self.assertRaises(ValueError):
            prepare(self.root, selection, self.out)
        (self.root / "graphify-out/link").symlink_to(self.root, target_is_directory=True)
        with self.assertRaises(ValueError):
            prepare(self.root, selection, self.root / "graphify-out/link/build")


if __name__ == "__main__":
    unittest.main()
