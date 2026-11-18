import bench from "./tools/bench.ts"
import ledger from "./tools/ledger.ts"
import stylecheck from "./tools/stylecheck.ts"
import reviewSnapshot from "./tools/review-snapshot.ts"
import { registerTool } from "./lib/tool.ts"
import { appendJsonl, benchPath, ledgerPath, loadConfig, now, readJsonl, reviewBenchPath, tierVariants } from "./lib/core.ts"
import { audit, fold } from "./lib/ledger.ts"

// Match canonical versioned releases only: fast/flex/dates and other providers
// are not interchangeable with the base model. Compare version components.
export function latest(models, tier) {
  const version = new RegExp(`^gpt-([0-9]+(?:\\.[0-9]+)*)-${tier}$`)
  return models
    .filter((m) => m.providerID === "openai" && m.enabled !== false)
    .flatMap((m) => {
      const match = version.exec(m.id)
      return match ? [{ id: m.id, parts: match[1].split(".").map(Number) }] : []
    })
    .sort((a, b) => {
      for (let i = 0; i < Math.max(a.parts.length, b.parts.length); i++) {
        const delta = (b.parts[i] ?? 0) - (a.parts[i] ?? 0)
        if (delta) return delta
      }
      return 0
    })[0]?.id
}

// Plugin.define in V2 is an identity helper; exporting the native definition
// directly keeps this Nix-owned plugin entirely free of npm dependencies.
export default {
  id: "nixsama.research-profiles",
  async setup(ctx) {
    if (process.env.NIXSAMA_OPENCODE_RESEARCH !== "1" ||
        process.env.OPENCODE_CONFIG_PROJECT_DISABLE !== "1") return
    const { data: inventory } = await ctx.model.list()
    const tiers = Object.fromEntries(Object.entries(tierVariants).map(([tier, [family, effort]]) => {
      const id = latest(inventory, family)
      if (!id) return [tier, undefined]
      const model = inventory.find((m) => m.providerID === "openai" && m.id === id && m.enabled !== false)
      const variant = model.variants?.some((v) => v.id === effort) ? effort : undefined
      if (!variant) console.warn(`opencode-research: ${id} does not advertise ${effort}; using its default variant.`)
      return [tier, { providerID: "openai", id, variant }]
    }))
    const refs = Object.values(tiers)
    const modelSet = refs.every(Boolean) ? refs.map((ref) => `${ref.id}.${ref.variant ?? "default"}`).join("+") : undefined
    const noPatch = (id: string) => id === "research" || id === "review" || /^(r|rv)-/.test(id)
    await ctx.agent.transform((editor) => {
      for (const [id, tier] of Object.entries({ ...ctx.options.tiers, compaction: "terra-low" })) {
        const model = tiers[tier]
        // This transform can run before OpenCode loads the Markdown, which
        // supplies the agent instructions but intentionally no model field.
        if (!model && !noPatch(id)) continue
        editor.update(id, (agent) => {
          if (model) agent.model = { ...model }
          if (noPatch(id)) agent.permissions.push({ action: "patch", resource: "*", effect: "deny" })
        })
      }
    })
    await ctx.tool.transform((editor) => {
      // V2 normally exposes patch, edit and write under the same visibility
      // action. Split patch out without changing its internal edit path checks.
      editor.update("patch", (tool) => {
        tool.options = { ...tool.options, permission: "patch" }
      })
      registerTool(editor, "ledger", ledger, ctx.location, ["research"], modelSet)
      registerTool(editor, "bench", bench, ctx.location, ["research", "review", "rv-scorer"], modelSet)
      registerTool(editor, "stylecheck", stylecheck, ctx.location, ["write"])
      registerTool(editor, "review_snapshot", reviewSnapshot, ctx.location, ["review", "rv-planter"])
    })
    const nudges = new Map<string, number>()
    const dir = ctx.location.directory
    await ctx.session.hook("experimental.idle", async (input) => {
      try {
        const info = await ctx.session.get({ sessionID: input.sessionID })
        if (info.parentID && /^(r|rv)-/.test(info.agent ?? "") && modelSet) {
          const expected = tiers[ctx.options.tiers[info.agent]]
          const ref = info.model ?? expected
          if (!ref || !expected || ref.providerID !== expected.providerID ||
              ref.id !== expected.id || ref.variant !== expected.variant) return
          appendJsonl(info.agent.startsWith("rv-") ? reviewBenchPath(dir, modelSet) : benchPath(dir, modelSet), {
            kind: "usage", t: now(), session: info.id, parent: info.parentID, agent: info.agent,
            model: `${ref.providerID}/${ref.id}${ref.variant ? `#${ref.variant}` : ""}`,
            usd: info.cost, tokens: info.tokens,
          })
        }
        if (info.agent !== "research" || input.background.some((b) => b.kind === "subagent" && b.sessionID === input.sessionID)) return
        const { must } = audit(fold(readJsonl(ledgerPath(dir))), loadConfig())
        const count = nudges.get(input.sessionID) ?? 0
        // Bound total nudges, even if the outstanding problems keep changing.
        if (must.length && count < 2) {
          nudges.set(input.sessionID, count + 1)
          await ctx.session.synthetic({
            sessionID: input.sessionID, description: "procedure check",
            text: `PROCEDURE CHECK:\n- ${must.join("\n- ")}\nResolve these steps or record why blocked.`,
          })
        }
      } catch {
        // Auxiliary accounting/auditing must not prevent a session going idle.
      }
    })
  },
}
