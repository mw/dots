/**
 * Generic extension shim — delegates all tool/event logic to extensions.py.
 *
 * This file is intended to be infrequently modified. Most extension logic
 * belongs in extensions.py.
 */
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  createBashTool,
  createEditTool,
  createReadTool,
  createWriteTool,
  type BashOperations,
  type EditOperations,
  type ExtensionAPI,
  type ExtensionContext,
  type ReadOperations,
  type WriteOperations,
} from "@earendil-works/pi-coding-agent";

const SCRIPT = path.join(
  path.dirname(fileURLToPath(import.meta.url)),
  "extensions.py",
);

interface Action {
  type: "set_active_tools" | "set_status" | "notify";
  tools?: string[];
  key?: string;
  text?: string | null;
  message?: string;
  level?: "info" | "warning" | "error";
}

interface PendingRequest {
  resolve: (value: any) => void;
  reject: (error: Error) => void;
  onData?: (data: Buffer) => void;
}

class PyProcess {
  private child = spawn("uv", ["run", SCRIPT, "serve"], {
    stdio: ["pipe", "pipe", "pipe"],
  });
  private nextId = 1;
  private pending = new Map<number, PendingRequest>();
  private buf = "";

  constructor() {
    this.child.stdout.on("data", (d) => this.onData(d));
    this.child.stderr.on("data", (d) => process.stderr.write(d));
    this.child.on("close", (code) => {
      for (const { reject } of this.pending.values()) {
        reject(new Error(`Python process exited (code ${code})`));
      }
      this.pending.clear();
    });
  }

  private onData(data: Buffer) {
    this.buf += data.toString("utf8");
    let i: number;
    while ((i = this.buf.indexOf("\n")) >= 0) {
      const line = this.buf.slice(0, i);
      this.buf = this.buf.slice(i + 1);
      if (line) this.handleLine(line);
    }
  }

  private handleLine(line: string) {
    const msg = JSON.parse(line);
    const req = this.pending.get(msg.id);
    if (!req) return;

    if (msg.error !== undefined) {
      this.pending.delete(msg.id);
      req.reject(new Error(msg.error));
    } else if (msg.data !== undefined) {
      req.onData?.(Buffer.from(msg.data, "base64"));
    } else if (msg.done !== undefined) {
      this.pending.delete(msg.id);
      req.resolve({ exitCode: msg.exitCode ?? null });
    } else {
      this.pending.delete(msg.id);
      req.resolve(msg.result);
    }
  }

  private send(
    method: string,
    params?: unknown,
    onData?: (data: Buffer) => void,
  ): { id: number; promise: Promise<any> } {
    const id = this.nextId++;
    const promise = new Promise<any>((resolve, reject) => {
      this.pending.set(id, { resolve, reject, onData });
    });
    this.child.stdin.write(JSON.stringify({ id, method, params }) + "\n");
    return { id, promise };
  }

  private cancel(id: number) {
    this.child.stdin.write(JSON.stringify({ cancel: id }) + "\n");
  }

  requestJson(method: string, params?: unknown): Promise<any> {
    return this.send(method, params).promise;
  }

  requestBinary(method: string, params: unknown): Promise<Buffer> {
    return this.send(method, params).promise.then((r) =>
      Buffer.from(r, "base64"),
    );
  }

  requestBash(
    command: string,
    onData: (data: Buffer) => void,
    signal?: AbortSignal,
    timeout?: number,
  ): Promise<{ exitCode: number | null }> {
    const { id, promise } = this.send("bash_exec", { command, timeout }, onData);
    if (signal) {
      const onAbort = () => this.cancel(id);
      signal.addEventListener("abort", onAbort, { once: true });
      promise.finally(() => signal.removeEventListener("abort", onAbort));
    }
    return promise;
  }

  shutdown() {
    this.child.kill("SIGTERM");
  }
}

function textResult(text: string) {
  return { content: [{ type: "text" as const, text }] };
}

function executeActions(
  actions: Action[] | undefined,
  pi: ExtensionAPI,
  ctx?: ExtensionContext,
) {
  for (const a of actions ?? []) {
    if (a.type === "set_active_tools" && a.tools) {
      pi.setActiveTools(a.tools);
    } else if (a.type === "set_status" && a.key) {
      ctx?.ui.setStatus(a.key, a.text ?? undefined);
    } else if (a.type === "notify" && a.message) {
      ctx?.ui.notify(a.message, a.level ?? "info");
    }
  }
}

function proxyBashOps(py: PyProcess): BashOperations {
  return {
    exec: (
      command: string,
      _cwd: string,
      opts: { onData: (d: Buffer) => void; signal?: AbortSignal; timeout?: number },
    ) => py.requestBash(command, opts.onData, opts.signal, opts.timeout),
  };
}

function proxyReadOps(py: PyProcess): ReadOperations {
  return {
    readFile: (p: string) => py.requestBinary("read_file", { path: p }),
    access: async (p: string) => { await py.requestJson("access", { path: p }); },
    detectImageMimeType: async (p: string) => {
      try {
        return (await py.requestJson("detect_mime", { path: p })) || null;
      } catch {
        return null;
      }
    },
  };
}

function proxyWriteOps(py: PyProcess): WriteOperations {
  return {
    writeFile: async (p: string, content: string) => {
      await py.requestJson("write_file", { path: p, content });
    },
    mkdir: async (dir: string) => { await py.requestJson("mkdir", { path: dir }); },
  };
}

function proxyEditOps(py: PyProcess): EditOperations {
  return {
    readFile: (p: string) => py.requestBinary("read_file", { path: p }),
    writeFile: async (p: string, content: string) => {
      await py.requestJson("write_file", { path: p, content });
    },
    access: async (p: string) => { await py.requestJson("access", { path: p }); },
  };
}

export default async function (pi: ExtensionAPI) {
  const py = new PyProcess();
  const m = await py.requestJson("init");
  const guestCwd: string = m.guestCwd;

  /** Register a built-in tool override whose operations are proxied to Python. */
  function overrideBuiltIn<C extends (cwd: string, opts?: any) => any>(
    create: C,
    ops: () => any,
  ) {
    pi.registerTool({
      ...create(guestCwd),
      async execute(id, params, signal, onUpdate) {
        return create(guestCwd, { operations: ops() }).execute(
          id,
          params,
          signal,
          onUpdate,
        );
      },
    });
  }

  for (const tool of m.tools) {
    pi.registerTool({
      name: tool.name,
      label: tool.label,
      description: tool.description,
      promptSnippet: tool.promptSnippet,
      promptGuidelines: tool.promptGuidelines,
      parameters: tool.parameters,
      executionMode: tool.executionMode,
      async execute(_id, params, _signal, _onUpdate, ctx) {
        try {
          const r = await py.requestJson("tool", { name: tool.name, params });
          executeActions(r.actions, pi, ctx);
          return textResult(r.text);
        } catch (e) {
          return textResult(`${tool.name} failed: ${e instanceof Error ? e.message : e}`);
        }
      },
    });
  }

  for (const cmd of m.commands) {
    pi.registerCommand(cmd.name, {
      description: cmd.description,
      handler: async (args, ctx) => {
        await ctx.waitForIdle();
        try {
          const r = await py.requestJson("command", { name: cmd.name, args });
          executeActions(r.actions, pi, ctx);
          if (r.text) ctx.ui.notify(r.text, "info");
          if (r.error) ctx.ui.notify(`${cmd.name} failed: ${r.error}`, "error");
        } catch (e) {
          ctx.ui.notify(`${cmd.name} failed: ${e instanceof Error ? e.message : e}`, "error");
        }
      },
    });
  }

  overrideBuiltIn(createBashTool, () => proxyBashOps(py));
  overrideBuiltIn(createReadTool, () => proxyReadOps(py));
  overrideBuiltIn(createWriteTool, () => proxyWriteOps(py));
  overrideBuiltIn(createEditTool, () => proxyEditOps(py));

  pi.on("session_start", async (_event, ctx) => {
    const r = await py.requestJson("event", {
      name: "session_start",
      event: {},
      activeTools: [],
    });
    executeActions(r.actions, pi, ctx);
  });

  pi.on("before_agent_start", async (event, ctx) => {
    const r = await py.requestJson("event", {
      name: "before_agent_start",
      event: { systemPrompt: event.systemPrompt, prompt: event.prompt },
      activeTools: pi.getActiveTools(),
    });
    executeActions(r.actions, pi, ctx);
    return r.result ?? {};
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    try {
      const r = await py.requestJson("event", {
        name: "session_shutdown",
        event: {},
        activeTools: pi.getActiveTools(),
      });
      executeActions(r.actions, pi, ctx);
    } finally {
      py.shutdown();
    }
  });

  pi.on("user_bash", async () => ({
    operations: proxyBashOps(py),
  }));
}
