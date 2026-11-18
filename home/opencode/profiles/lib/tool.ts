// Minimal JSON Schema authoring helpers for the profile tools. Runtime
// authorization lives in execute, not in tool visibility or agent prompts.
type Schema = Record<string, any>
function field(schema: Schema, required = true): any {
  return {
    schema, required,
    optional: () => field(schema, false),
    describe: (description: string) => field({ ...schema, description }, required),
    min: (value: number) => field({ ...schema, minimum: value }, required),
    max: (value: number) => field({ ...schema, maximum: value }, required),
    int: () => field({ ...schema, type: "integer" }, required),
  }
}
function object(fields: Record<string, any>) {
  return {
    type: "object",
    properties: Object.fromEntries(Object.entries(fields).map(([k, v]) => [k, v.schema])),
    required: Object.keys(fields).filter((k) => fields[k].required),
    additionalProperties: false,
  }
}
export const tool = Object.assign((definition) => definition, {
  schema: {
    string: () => field({ type: "string" }),
    number: () => field({ type: "number" }),
    boolean: () => field({ type: "boolean" }),
    enum: (values: readonly string[]) => field({ type: "string", enum: values }),
    object: (fields) => field(object(fields)),
    array: (items) => field({ type: "array", items: items.schema }),
  },
})

export function registerTool(editor, name, definition, location, agents, modelSet?: string) {
  editor.add({
    name,
    description: definition.description,
    input: object(definition.args),
    async execute(input, context) {
      if (!agents.includes(context.agent))
        return { content: `ERROR: ${name} is only available to ${agents.join(", ")}.` }
      return { content: await definition.execute(input, { directory: location.directory, modelSet, agent: context.agent }) }
    },
  })
}
