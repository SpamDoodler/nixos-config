import { closeSync, constants, fstatSync, lstatSync, mkdirSync, openSync, readSync, readdirSync, realpathSync, rmSync, writeFileSync } from "node:fs"
import { basename, isAbsolute, join, relative, sep } from "node:path"
import { workspacePath } from "../lib/core.ts"
import { tool } from "../lib/tool.ts"

const ignored = new Set([".git", ".opencode", ".opencode-tmp", ".agents", ".claude", "node_modules"])
const excluded = (name: string) => ignored.has(name) || /(?:\.env(?:\.|$)|credential|secret)/i.test(name)
const byteLimit = 128 * 1024 * 1024
const entryLimit = 10_000

export default tool({
  description: "Copy a workspace file or directory into a new review/<slug>/target/ without editing the original. Copies directory contents or preserves a single file's basename. Does not overwrite snapshots.",
  args: {
    source: tool.schema.string().describe("Workspace-relative path to the user-selected manuscript file or directory"),
    slug: tool.schema.string().describe("Review directory name, using letters, digits, underscores and hyphens"),
  },
  async execute({ source, slug }, { directory }) {
    let created: string | undefined
    try {
      if (!/^[a-zA-Z0-9][a-zA-Z0-9_-]{0,127}$/.test(slug)) throw new Error("Invalid review slug")
      if (isAbsolute(source)) throw new Error("Use a workspace-relative source path")
      const parts = source.split("/").filter((part) => part !== "" && part !== ".")
      if (!parts.length || parts[0] === "review" || parts.some((part) => part === ".." || excluded(part)))
        throw new Error("Choose a manuscript path inside the workspace, outside review output and private directories")
      const root = realpathSync(directory)
      let input = root
      for (const part of parts) {
        input = join(input, part)
        if (lstatSync(input).isSymbolicLink()) throw new Error("Snapshot source must not traverse symlinks")
      }
      const target = workspacePath(root, "review", slug, "target")
      mkdirSync(workspacePath(root, "review", slug), { recursive: true })
      // Exclusive creation also prevents two reviewers using the same slug from
      // mixing files. On failure, remove only the directory this call created.
      mkdirSync(target, { mode: 0o700 })
      created = target
      let entries = 0, files = 0, bytes = 0
      const copy = (src: string, dst: string, contentsOnly = false) => {
        if (++entries > entryLimit) throw new Error("Snapshot exceeds 10,000 entries")
        const stats = lstatSync(src)
        if (stats.isDirectory()) {
          if (!contentsOnly) mkdirSync(dst, { mode: 0o700 })
          for (const name of readdirSync(src)) {
            if (!excluded(name)) copy(join(src, name), join(dst, name))
          }
          return
        }
        if (!stats.isFile() || stats.nlink !== 1) throw new Error("Snapshot contains a symlink, hard link or special file")
        const fd = openSync(src, constants.O_RDONLY | constants.O_NOFOLLOW | constants.O_NONBLOCK)
        try {
          const before = fstatSync(fd)
          if (!before.isFile() || before.nlink !== 1 || bytes + before.size > byteLimit)
            throw new Error("Snapshot requires regular single-link files totaling at most 128 MiB")
          const data = Buffer.alloc(before.size)
          const count = data.length ? readFileInto(fd, data) : 0
          const after = fstatSync(fd)
          if (count !== before.size || after.size !== before.size || after.mtimeMs !== before.mtimeMs)
            throw new Error("Source changed during snapshot; retry after it is stable")
          writeFileSync(dst, data, { flag: "wx", mode: 0o600 })
          bytes += count
          files++
        } finally {
          closeSync(fd)
        }
      }
      if (lstatSync(input).isDirectory()) copy(input, target, true)
      else copy(input, join(target, basename(input)))
      if (!files) throw new Error("Snapshot contains no eligible files")
      return `Snapshot ready: ${relative(root, target).split(sep).join("/")}/ (${files} files).`
    } catch (error) {
      if (created) rmSync(created, { recursive: true, force: true })
      const message = (error as NodeJS.ErrnoException).code === "EEXIST"
        ? "target already exists; reuse it or choose a new slug"
        : error instanceof Error ? error.message : String(error)
      return `Snapshot refused: ${message}.`
    }
  },
})

function readFileInto(fd: number, buffer: Buffer) {
  let offset = 0
  while (offset < buffer.length) {
    const n = readSync(fd, buffer, offset, buffer.length - offset, null)
    if (!n) break
    offset += n
  }
  return offset
}
