import { Agent } from "@earendil-works/pi-agent-core";
import type { Usage } from "@earendil-works/pi-ai";
import type { ToolDefinition } from "@earendil-works/pi-coding-agent";

export function createAgentTool(names: string[]): ToolDefinition {
  return {
    name: "agent",
    label: "Agent",
    description:
      "Delegate work to a subagent. Use for large tasks involving many " +
      "separate instances or files. Orchestrate subagents with codemode, " +
      "bounding concurrency and requesting from each a concise summary. ",
    parameters: {
      type: "object",
      properties: {
        prompt: { type: "string" },
        model: {
          type: "string",
          description:
            "ID of the model to use. Omit if not specified by the user.",
        },
      },
      required: ["prompt"],
    },
    executionMode: "parallel",
    async execute(_id, { prompt, model: requested }, signal, _onUpdate, ctx) {
      signal?.throwIfAborted();
      let model = ctx.model;
      if (requested !== undefined) {
        model = ctx.modelRegistry
          .getAll()
          .find(
            (model) =>
              (model.provider === ctx.model?.provider &&
                model.id === requested) ||
              `${model.provider}/${model.id}` === requested,
          );
        if (!model) throw new Error(`Unknown model: ${requested}`);
      }
      if (!model) throw new Error("No model selected");

      const child = new Agent({
        initialState: {
          model,
          thinkingLevel: ctx.thinkingLevel,
          systemPrompt:
            ctx.getSystemPrompt() +
            "\n\nNOTE: You are a subagent being invoked non-interactively. " +
            "If the task can be completed as specified, complete it without " +
            "stopping, and return the requested summary.",
          tools: ctx.tools
            .filter((tool) => names.includes(tool.name))
            .map((tool) => ({
              ...tool,
              async execute(_id, args, signal, onUpdate) {
                const { result, isError } = await ctx.executeTool(
                  tool.name,
                  args,
                  {
                    signal,
                    onUpdate,
                  },
                );
                return { ...result, isError };
              },
            })),
        },
        streamFn: (model, context, options) =>
          ctx.modelRegistry.streamSimple(model, context, options),
      });

      const abort = () => child.abort();
      signal?.addEventListener("abort", abort, { once: true });
      try {
        await child.prompt(prompt);
        signal?.throwIfAborted();
        const last = child.state.messages.at(-1);
        if (!last || last.role !== "assistant") {
          throw new Error("Child agent ended without an assistant response");
        }
        const counts = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 };
        const usage: Usage = {
          ...counts,
          totalTokens: 0,
          cost: { ...counts, total: 0 },
        };
        for (const message of child.state.messages) {
          if (message.role !== "assistant") continue;
          for (const key of Object.keys(counts) as (keyof typeof counts)[]) {
            usage[key] += message.usage[key];
            usage.cost[key] += message.usage.cost[key];
          }
          usage.totalTokens += message.usage.totalTokens;
          usage.cost.total += message.usage.cost.total;
        }
        const isError = last.stopReason !== "stop";
        return {
          content: isError
            ? [
                {
                  type: "text",
                  text:
                    last.errorMessage ||
                    `Child agent stopped: ${last.stopReason}`,
                },
              ]
            : last.content.filter((block) => block.type === "text"),
          details: undefined,
          isError,
          usage,
        };
      } finally {
        signal?.removeEventListener("abort", abort);
      }
    },
  };
}
