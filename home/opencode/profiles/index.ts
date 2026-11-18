import bench from "./tools/bench.ts"
import ledger from "./tools/ledger.ts"
import stylecheck from "./tools/stylecheck.ts"
import reviewSnapshot from "./tools/review-snapshot.ts"
import { registerTool } from "./lib/tool.ts"
import { appendJsonl, benchPath, ledgerPath, loadConfig, now, readJsonl, reviewBenchPath } from "./lib/core.ts"
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
    const tiers = Object.fromEntries(["luna", "terra", "sol", "astra"].map((tier) => [tier, latest(inventory, tier)]))
    const modelSet = Object.values(tiers).every(Boolean) ? Object.values(tiers).join("+") : undefined
    await ctx.agent.transform((editor) => {
      for (const [id, tier] of Object.entries({ ...ctx.options.tiers, compaction: "terra" })) {
        const model = tiers[tier]
        // This transform can run before OpenCode loads the Markdown, which
        // supplies the agent instructions but intentionally no model field.
        if (!model) continue
        editor.update(id, (agent) => { agent.model = { providerID: "openai", id: model } })
      }
    })
    await ctx.tool.transform((editor) => {
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
        if (info.parentID && /^(r|rv|w)-/.test(info.agent ?? "") && modelSet) {
          const ref = info.model ?? { providerID: "openai", id: tiers[ctx.options.tiers[info.agent]] }
          if (!ref.id || ref.providerID !== "openai" || !Object.values(tiers).includes(ref.id)) return
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
