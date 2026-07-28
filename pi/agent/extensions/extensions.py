# /// script
# requires-python = ">=3.12"
# dependencies = ["microsandbox", "httpx", "pydantic"]
# ///
import asyncio
import base64
import functools
import hashlib
import httpx
import json
import os
import shlex
import subprocess
import sys
import tempfile
import time
from contextlib import asynccontextmanager, suppress
from pathlib import Path

from typing import Any

from microsandbox import (
    Image,
    MicrosandboxError,
    MountConfig,
    MountKind,
    Sandbox,
    SandboxNotFoundError,
    Snapshot,
    StatVirtualization,
)
from pydantic import BaseModel, ConfigDict
from pydantic.alias_generators import to_camel

GUEST_WORKSPACE = "/workspace"
DISK_SIZE_MIB = 8192
MEMORY_MIB = 4096
KAGI_BASE_URL = "https://kagi.com/api/v1"
CWD = os.getcwd()
SANDBOX_NIX = Path(__file__).resolve().parent / "sandbox.nix"
HIDDEN_TOOLS = ["find", "grep"]


class DirEntry(BaseModel):
    name: str
    host_path: str


def _xattrs_supported(path: str) -> bool:
    try:
        os.setxattr(path, "user.pi_test_xattrs", b"")
        os.removexattr(path, "user.pi_test_xattrs")
        return True
    except OSError:
        return False
    except AttributeError:
        # macOS
        return True


def _bind_mount(path: str, readonly: bool = False) -> MountConfig:
    # Use stat virtualization if possible. Git will complain if files appear to
    # be owned by a different user.
    if _xattrs_supported(path):
        return MountConfig(kind=MountKind.BIND, bind=path, readonly=readonly)
    return MountConfig(
        kind=MountKind.BIND,
        bind=path,
        readonly=readonly,
        stat_virtualization=StatVirtualization.OFF,
    )


def _write_line(msg: dict[str, Any]) -> None:
    """Write a single JSON line to stdout."""
    os.write(1, (json.dumps(msg) + "\n").encode())


# Schemas & base classes


class ToolSchema(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: str
    label: str
    description: str
    parameters: dict[str, Any]
    execution_mode: str = "parallel"
    confirm: bool = False
    """Whether tool calls must be gated on a tool_confirm check."""


class CommandSchema(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    name: str
    description: str


class Tool:
    schema: ToolSchema

    def confirm(self, params: dict[str, Any]) -> str | None:
        """Return a confirmation message to prompt the user, or None."""
        return None

    async def handle(self, params: dict[str, Any]) -> dict[str, Any]:
        raise NotImplementedError


class Command:
    schema: CommandSchema

    async def handle(self, raw_args: str) -> dict[str, Any]:
        raise NotImplementedError


class Subcommand:
    name: str

    async def handle(self, args: dict[str, Any]) -> Any:
        raise NotImplementedError


# Registries & decorators

_tool_registry: dict[str, Tool] = {}
_command_registry: dict[str, Command] = {}
_subcommand_registry: dict[str, Subcommand] = {}


def register_tool(cls):
    instance = cls()
    _tool_registry[instance.schema.name] = instance
    return cls


def register_command(cls):
    instance = cls()
    _command_registry[instance.schema.name] = instance
    return cls


def register_subcommand(cls):
    instance = cls()
    _subcommand_registry[instance.name] = instance
    return cls


# Tools


async def _dump_extract(resp: dict[str, Any]) -> str:
    """Write extract results as JSON to a temp file inside the sandbox."""
    fd, fpath = tempfile.mkstemp(dir="/tmp", prefix="extract_", suffix=".json")
    os.close(fd)
    os.unlink(fpath)
    async with sbm.session() as sb:
        await sb.fs.write(fpath, json.dumps(resp, indent=2).encode("utf-8"))
    return f"Results saved to `{fpath}`."


@register_tool
class Search(Tool):
    schema = ToolSchema(
        name="search",
        label="Kagi Search",
        description=(
            "Search the web using the Kagi REST API. Returns ranked "
            "results, each with a title, URL, and snippet."
        ),
        parameters={
            "type": "object",
            "properties": {
                "query": {"type": "string", "description": "Search query"},
                "limit": {
                    "type": "integer",
                    "description": ("Maximum number of results to return (default 8)"),
                    "default": 8,
                },
            },
            "required": ["query"],
        },
    )

    async def handle(self, params: dict[str, Any]) -> dict[str, Any]:
        key = os.environ.get("KAGI_API_KEY")
        if not key:
            raise RuntimeError("missing KAGI_API_KEY")
        limit = params.get("limit", 8)
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{KAGI_BASE_URL}/search",
                headers={
                    "Authorization": f"Bearer {key}",
                    "Content-Type": "application/json",
                },
                json={
                    "query": params["query"],
                    "workflow": "search",
                    "limit": limit,
                },
            )
            resp.raise_for_status()
            results = resp.json()["data"].get("search", [])
            for r in results:
                r.pop("props", None)
            return {"text": json.dumps(results, indent=2)}


@register_tool
class Extract(Tool):
    schema = ToolSchema(
        name="extract",
        label="Kagi Extract",
        description=(
            "Retrieve the readable text content of one or more web "
            "pages using the Kagi extract API. Results are written "
            "as JSON to a temp file under /tmp/pi_agent/ and the file "
            "path is returned. Structure: {meta, data: [{url, "
            "markdown (success) or error (failure)}]}. Use "
            "`jq` to query, e.g. `jq '.data[0].markdown' <path>`. "
            "Accepts 1-10 HTTPS URLs."
        ),
        parameters={
            "type": "object",
            "properties": {
                "urls": {
                    "type": "array",
                    "description": "Page URLs to extract (1-10 HTTPS URLs)",
                    "items": {"type": "string"},
                    "minItems": 1,
                    "maxItems": 10,
                },
                "timeout": {
                    "type": "number",
                    "description": (
                        "Time budget in seconds for the bulk fetch (optional)"
                    ),
                },
            },
            "required": ["urls"],
        },
    )

    async def handle(self, params: dict[str, Any]) -> dict[str, Any]:
        key = os.environ.get("KAGI_API_KEY")
        if not key:
            raise RuntimeError("missing KAGI_API_KEY")
        body: dict[str, Any] = {
            "pages": [{"url": u} for u in params["urls"]],
            "format": "json",
        }
        timeout = params.get("timeout")
        if timeout is not None:
            body["timeout"] = timeout
        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{KAGI_BASE_URL}/extract",
                headers={
                    "Authorization": f"Bearer {key}",
                    "Content-Type": "application/json",
                },
                json=body,
            )
            resp.raise_for_status()
            return {"text": await _dump_extract(resp.json())}


@register_tool
class Nvr(Tool):
    schema = ToolSchema(
        name="nvr",
        label="Neovim Remote",
        description=(
            "Direct the user to file locations using neovim's "
            "quickfix list. Runs nvr on the host, outside the "
            "sandbox. Accepts a list of locations, each with a "
            "relative file name, line number, and description."
        ),
        parameters={
            "type": "object",
            "properties": {
                "locations": {
                    "type": "array",
                    "description": "List of file locations to direct the user to",
                    "items": {
                        "type": "object",
                        "properties": {
                            "file": {
                                "type": "string",
                                "description": "Relative file path",
                            },
                            "line": {
                                "type": "number",
                                "description": "Line number",
                            },
                            "description": {
                                "type": "string",
                                "description": "Explanation of code",
                            },
                            "col": {
                                "type": "number",
                                "description": "Column (default 1)",
                            },
                        },
                        "required": ["file", "line", "description"],
                    },
                },
            },
            "required": ["locations"],
        },
    )

    async def handle(self, params: dict[str, Any]) -> dict[str, Any]:
        locations = params["locations"]
        summary = ", ".join(f"{loc['file']}:{loc['line']}" for loc in locations)

        socket = Path(CWD) / ".nvim.sock"
        if not socket.exists():
            return {"text": f"nvr socket not found at {socket}. Is neovim running?"}

        entries = [
            json.dumps(
                {
                    "filename": str((Path(CWD) / loc["file"]).resolve()),
                    "lnum": loc["line"],
                    "col": loc.get("col", 1),
                    "text": loc["description"],
                }
            )
            for loc in locations
        ]
        vim_cmd = f"call setqflist([{', '.join(entries)}]) | copen"

        result = subprocess.run(
            ["nvr", "--servername", str(socket), "-c", vim_cmd],
            capture_output=True,
            text=True,
            cwd=CWD,
        )
        if result.returncode != 0:
            return {
                "text": f"nvr exited with code {result.returncode}: "
                f"{result.stderr or result.stdout}",
            }
        return {"text": f"Directed user to {summary}"}


@register_tool
class Jj(Tool):
    schema = ToolSchema(
        name="jj",
        label="Jujutsu",
        description=(
            "Run a jj (Jujutsu) command on the host, outside the "
            "sandbox. Use this instead of running jj via bash, since "
            "jj workspaces do not work inside the sandbox. The user "
            "is asked to confirm `jj util` and `jj run` invocations."
        ),
        parameters={
            "type": "object",
            "properties": {
                "args": {
                    "type": "array",
                    "description": ('Arguments to pass to jj, e.g. ["status"]'),
                    "items": {"type": "string"},
                    "minItems": 1,
                },
            },
            "required": ["args"],
        },
        confirm=True,
    )

    def confirm(self, params: dict[str, Any]) -> str | None:
        args = params["args"]
        if args[0] in ("util", "run"):
            return f"Allow running on the host: jj {shlex.join(args)}?"
        return None

    async def handle(self, params: dict[str, Any]) -> dict[str, Any]:
        args = params["args"]
        result = subprocess.run(
            ["jj", *args],
            capture_output=True,
            text=True,
            cwd=CWD,
            timeout=120,
        )
        output = result.stdout + result.stderr
        if result.returncode != 0:
            output += f"\n(jj exited with code {result.returncode})"
        return {"text": output.strip() or "(no output)"}


# Commands


@register_command
class Dirs(Command):
    schema = CommandSchema(
        name="dirs",
        description=(
            "Manage read-only host directories mounted in the sandbox. "
            "Usage: /dirs add <name> <host-path> | "
            "/dirs reset | /dirs list"
        ),
    )

    async def handle(self, raw_args: str) -> dict[str, Any]:
        parts = shlex.split(raw_args)
        if not parts:
            return {
                "error": (
                    "Usage: /dirs add <name> <host-path> | /dirs reset | /dirs list"
                )
            }

        subcmd = parts[0]

        if subcmd == "add":
            return await self._add(parts[1:])
        elif subcmd == "reset":
            return await self._reset()
        elif subcmd == "list":
            return await self._list()
        else:
            return {"error": f"Unknown subcommand: {subcmd!r}"}

    async def _add(self, args: list[str]) -> dict[str, Any]:
        if len(args) != 2:
            return {"error": "Usage: /dirs add <name> <host-path>"}

        name, host_path = args
        if not name or "/" in name:
            return {"error": f"Invalid name {name!r}: must be a single path segment"}

        abs_host = os.path.abspath(os.path.expanduser(host_path))
        if not os.path.isdir(abs_host):
            return {"error": f"Not a directory: {abs_host}"}

        guest_path = f"/src/{name}"
        dirs = [d for d in await sbm.load_dirs() if d.name != name]
        dirs.append(DirEntry(name=name, host_path=abs_host))

        await sbm.recreate(dirs)

        return {
            "actions": [
                {
                    "type": "notify",
                    "message": (f"Mounted {abs_host} → {guest_path} (read-only)"),
                    "level": "info",
                },
            ],
        }

    async def _reset(self) -> dict[str, Any]:
        dirs = await sbm.load_dirs()
        if not dirs:
            return {"text": "No /src directories are currently mounted."}

        await sbm.recreate([])

        removed = ", ".join(f"/src/{d.name}" for d in dirs)
        return {
            "actions": [
                {
                    "type": "notify",
                    "message": f"Unmounted: {removed}",
                    "level": "info",
                },
            ],
        }

    async def _list(self) -> dict[str, Any]:
        dirs = await sbm.load_dirs()
        if not dirs:
            return {"text": "No /src directories are currently mounted."}

        lines = [f"/src/{d.name} ← {d.host_path} (read-only)" for d in dirs]
        return {"text": "\n".join(lines)}


# Manifest


def manifest() -> dict[str, Any]:
    return {
        "tools": [t.schema.model_dump(by_alias=True) for t in _tool_registry.values()],
        "commands": [
            c.schema.model_dump(by_alias=True) for c in _command_registry.values()
        ],
        "events": [
            "session_start",
            "before_agent_start",
            "session_shutdown",
            "user_bash",
        ],
        "overrides": ["bash", "read", "write", "edit"],
        "hideTools": HIDDEN_TOOLS,
        "guestCwd": GUEST_WORKSPACE,
    }


# Sandbox lifecycle


class SandboxManager:
    """
    Manages the sandbox for a host working directory.
    """

    def __init__(self, cwd: str = CWD) -> None:
        self.cwd = cwd
        # Serializes sandbox/snapshot lifecycle operations. Requests are
        # handled concurrently, so without this two tasks can both observe a
        # missing sandbox/snapshot and collide creating it.
        self._lock = asyncio.Lock()

    @functools.cached_property
    def image_tag(self) -> str:
        store_path = subprocess.run(
            [
                "nix",
                "build",
                "-f",
                str(SANDBOX_NIX),
                "--no-link",
                "--print-out-paths",
            ],
            check=True,
            cwd=SANDBOX_NIX.parent,
            capture_output=True,
            text=True,
        ).stdout.strip()
        return f"pi-sandbox:{hashlib.sha256(store_path.encode()).hexdigest()[:12]}"

    @property
    def name(self) -> str:
        h = hashlib.sha256()
        h.update(self.cwd.encode())
        h.update(self.image_tag.encode())
        return f"pi-{h.hexdigest()[:12]}"

    @property
    def snapshot_name(self) -> str:
        return f"snap-{self.image_tag.split(':')[1]}"

    def ensure_image(self) -> str:
        """
        Use nix to build the container image to load into microsandbox
        """
        tag = self.image_tag

        result = subprocess.run(
            ["msb", "image", "inspect", tag],
            capture_output=True,
        )
        if result.returncode == 0:
            return tag

        store_path = subprocess.run(
            [
                "nix",
                "build",
                "-f",
                str(SANDBOX_NIX),
                "--no-link",
                "--print-out-paths",
            ],
            check=True,
            cwd=SANDBOX_NIX.parent,
            capture_output=True,
            text=True,
        ).stdout.strip()

        with subprocess.Popen(
            ["gunzip", "-c", store_path], stdout=subprocess.PIPE
        ) as gunzip:
            subprocess.run(
                ["msb", "load", "--tag", tag],
                stdin=gunzip.stdout,
                check=True,
            )
        return tag

    @staticmethod
    async def prune_old_images(max_age_days: int = 7) -> None:
        """
        Remove cached images not used by any running sandbox
        and older than max_age_days.
        """
        cutoff_ms = (time.time() - max_age_days * 86400) * 1000

        running: set[str] = set()
        for handle in await Sandbox.list():
            if handle.status != "running":
                continue
            config = handle.config()
            image = config.get("image")
            if isinstance(image, str):
                running.add(image)
            elif isinstance(image, dict):
                ref = image.get("reference") or image.get("_reference")
                if ref:
                    running.add(ref)

        for img in await Image.list():
            last_used = img.last_used_at
            if last_used is None:
                continue
            if last_used >= cutoff_ms:
                continue
            if img.reference in running:
                continue
            with suppress(MicrosandboxError):
                # Best-effort: e.g. ImageInUseError from a concurrent session.
                await img.remove()

    @staticmethod
    def dirs_from_config(cfg: dict[str, Any]) -> list[DirEntry]:
        dirs: list[DirEntry] = []
        for m in cfg.get("mounts", []):
            if m.get("type") != "Bind":
                continue
            guest = m.get("guest", "")
            if not guest.startswith("/src/"):
                continue
            name = guest[len("/src/") :]
            if not name or "/" in name:
                continue
            dirs.append(DirEntry(name=name, host_path=m["host"]))
        return dirs

    async def load_dirs(self) -> list[DirEntry]:
        for handle in await Sandbox.list_with(labels={"pi.cwd": self.cwd}):
            return self.dirs_from_config(handle.config())
        return []

    async def find(self):
        try:
            return await Sandbox.get(self.name)
        except SandboxNotFoundError:
            return None

    async def ensure_snapshot(self, rebuild: bool = False) -> str:
        """
        Ensure a snapshot of the base image exists.

        Caller must hold ``self._lock``. Snapshots are keyed by image tag,
        so they are shared across sandboxes and concurrent pi processes.
        """
        snap = self.snapshot_name
        if rebuild:
            with suppress(MicrosandboxError):
                await Snapshot.remove(snap, force=True)
        elif any(h.name == snap for h in await Snapshot.list()):
            return snap

        tag = self.ensure_image()

        base_name = f"base-{self.name}"
        try:
            base = await Sandbox.create(
                base_name,
                image=Image.oci(tag, upper_size_mib=DISK_SIZE_MIB),
                memory=MEMORY_MIB,
                replace=True,
            )
            await base.stop()
            # Snapshot.create stages the artifact and swaps it in atomically,
            # so force=True is idempotent even when another pi process builds
            # the same snapshot concurrently.
            await Snapshot.create(base_name, name=snap, force=True)
        finally:
            with suppress(MicrosandboxError):
                await Sandbox.remove(base_name)
        return snap

    async def get(self, extra_dirs: list[DirEntry] | None = None):
        """
        Get or create the sandbox.

        Returns ``(handle, owns)`` where ``owns`` is True when this call
        started or created the sandbox (and the caller should detach after
        use).
        """
        async with self._lock:
            handle = await self.find()
            if handle:
                try:
                    if handle.status == "running":
                        return await handle.connect(), False
                    return await handle.start(detached=True), True
                except MicrosandboxError:
                    # Stale or broken sandbox (e.g. removed or stopped by
                    # another process); recreate it below.
                    await self._remove_sandbox(self.name)

            dirs = extra_dirs if extra_dirs is not None else await self.load_dirs()
            volumes = {GUEST_WORKSPACE: _bind_mount(self.cwd)}
            for d in dirs:
                volumes[f"/src/{d.name}"] = _bind_mount(d.host_path, readonly=True)

            snap = await self.ensure_snapshot()

            try:
                sb = await self._create(snap, volumes)
            except MicrosandboxError:
                # The snapshot may be stale or corrupt (e.g. left behind by
                # an interrupted build or an msb upgrade); rebuild it once.
                snap = await self.ensure_snapshot(rebuild=True)
                sb = await self._create(snap, volumes)

            # Remove stale sandboxes from previous image tags for this cwd.
            for old in await Sandbox.list_with(labels={"pi.cwd": self.cwd}):
                if old.name != self.name:
                    await self._remove_sandbox(old.name, handle=old)

            await self.prune_old_images()
            return sb, True

    async def _create(self, snap: str, volumes: dict[str, MountConfig]):
        return await Sandbox.create(
            self.name,
            snapshot=snap,
            detached=True,
            replace=True,
            memory=MEMORY_MIB,
            volumes=volumes,
            workdir=GUEST_WORKSPACE,
            labels={"pi.cwd": self.cwd},
        )

    @staticmethod
    async def _remove_sandbox(name: str, handle=None) -> None:
        with suppress(MicrosandboxError):
            handle = handle or await Sandbox.get(name)
            if handle.status == "running":
                await handle.kill()
        with suppress(MicrosandboxError):
            await Sandbox.remove(name)

    @asynccontextmanager
    async def session(self):
        sb, owns = await self.get()
        try:
            yield sb
        finally:
            if owns:
                await sb.detach()

    async def shutdown(self) -> None:
        handle = await self.find()
        if handle and handle.status == "running":
            with suppress(MicrosandboxError):
                await handle.request_stop()

    async def recreate(self, extra_dirs: list[DirEntry] | None = None) -> None:
        await self._remove_sandbox(self.name)

        sb, owns = await self.get(extra_dirs=extra_dirs)
        if owns:
            await sb.detach()


sbm = SandboxManager()


# RPC commands


@register_subcommand
class Init(Subcommand):
    name = "init"

    async def handle(self, args: dict[str, Any]) -> dict[str, Any]:
        return manifest()


@register_subcommand
class EventDispatch(Subcommand):
    name = "event"

    async def handle(self, args: dict[str, Any]) -> dict[str, Any]:
        name = args["name"]
        event = args.get("event", {})
        active_tools = args.get("activeTools", [])

        if name == "session_start":
            sandbox_name = sbm.name
            return {
                "result": {},
                "actions": [
                    {
                        "type": "set_status",
                        "key": "microsandbox",
                        "text": f"sandbox ({sandbox_name})",
                    }
                ],
            }
        elif name == "before_agent_start":
            tools = [t for t in active_tools if t not in HIDDEN_TOOLS]
            local_line = f"Current working directory: {CWD}"
            guest_line = (
                f"Current working directory: {GUEST_WORKSPACE} "
                f"(microsandbox; host workspace mounted from {CWD})"
            )
            dirs = await sbm.load_dirs()
            mount_lines = [guest_line]
            if dirs:
                mounts = ", ".join(f"/src/{d.name} ← {d.host_path}" for d in dirs)
                mount_lines.append(f"Additional read-only mounts: {mounts}")
            extra = "\n".join(mount_lines)
            system_prompt = event.get("systemPrompt", "")
            if local_line in system_prompt:
                system_prompt = system_prompt.replace(local_line, extra)
            else:
                system_prompt = f"{system_prompt}\n\n{extra}"
            return {
                "result": {"systemPrompt": system_prompt},
                "actions": [
                    {"type": "set_active_tools", "tools": tools},
                ],
            }
        elif name == "session_shutdown":
            await sbm.shutdown()
            return {
                "result": {},
                "actions": [
                    {"type": "set_status", "key": "microsandbox", "text": None}
                ],
            }
        else:
            raise ValueError(f"Unknown event: {name}")


@register_subcommand
class ToolConfirm(Subcommand):
    name = "tool_confirm"

    async def handle(self, args: dict[str, Any]) -> str | None:
        tool = _tool_registry.get(args["name"])
        if tool is None:
            raise ValueError(f"Unknown tool: {args['name']}")
        return tool.confirm(args.get("params", {}))


@register_subcommand
class ToolDispatch(Subcommand):
    name = "tool"

    async def handle(self, args: dict[str, Any]) -> dict[str, Any]:
        name = args["name"]
        params = args.get("params", {})

        tool = _tool_registry.get(name)
        if tool is None:
            raise ValueError(f"Unknown tool: {name}")

        return await tool.handle(params)


@register_subcommand
class CommandDispatch(Subcommand):
    name = "command"

    async def handle(self, args: dict[str, Any]) -> dict[str, Any]:
        name = args["name"]
        raw_args = args.get("args", "")

        cmd = _command_registry.get(name)
        if cmd is None:
            raise ValueError(f"Unknown command: {name}")

        return await cmd.handle(raw_args)


@register_subcommand
class ReadFile(Subcommand):
    name = "read_file"

    async def handle(self, args: dict[str, Any]) -> str:
        async with sbm.session() as sb:
            data = await sb.fs.read(args["path"])
        return base64.b64encode(data).decode()


@register_subcommand
class WriteFile(Subcommand):
    name = "write_file"

    async def handle(self, args: dict[str, Any]) -> None:
        async with sbm.session() as sb:
            await sb.fs.write(args["path"], args["content"].encode("utf-8"))


@register_subcommand
class Access(Subcommand):
    name = "access"

    async def handle(self, args: dict[str, Any]) -> None:
        async with sbm.session() as sb:
            result = await sb.shell(f"test -r {shlex.quote(args['path'])}")
        if not result.success:
            raise FileNotFoundError(f"File not accessible: {args['path']}")


@register_subcommand
class Mkdir(Subcommand):
    name = "mkdir"

    async def handle(self, args: dict[str, Any]) -> None:
        async with sbm.session() as sb:
            await sb.fs.mkdir(args["path"])


@register_subcommand
class DetectMime(Subcommand):
    name = "detect_mime"

    async def handle(self, args: dict[str, Any]) -> str:
        path = args["path"]
        async with sbm.session() as sb:
            result = await sb.shell(
                f"file --mime-type -b {shlex.quote(path)} 2>/dev/null || true"
            )
        mime = result.stdout_text.strip()
        if mime.startswith("image/"):
            return mime
        ext = Path(path).suffix.lower().lstrip(".")
        ext_map = {
            "png": "image/png",
            "jpg": "image/jpeg",
            "jpeg": "image/jpeg",
            "gif": "image/gif",
            "webp": "image/webp",
            "bmp": "image/bmp",
        }
        return ext_map.get(ext, "")


# Server


async def _handle_bash(req_id: int, args: dict[str, Any]) -> None:
    timeout = args.get("timeout")
    async with sbm.session() as sb:
        handle = await sb.shell_stream(args["command"], timeout=timeout, stdin=b"")
        code = 1
        try:
            # shell_stream() does not enforce the timeout itself (msb 0.6.6),
            # so apply a client-side deadline and kill the process on expiry.
            async with asyncio.timeout(timeout):
                async for event in handle:
                    if event.event_type in ("stdout", "stderr"):
                        _write_line(
                            {
                                "id": req_id,
                                "data": base64.b64encode(event.data).decode(),
                            }
                        )
                    elif event.event_type == "exited":
                        code = event.code if event.code is not None else 1
                        break
        except TimeoutError:
            with suppress(MicrosandboxError):
                await handle.kill()
                async for _ in handle:  # drain until exited
                    pass
            code = 124
        _write_line({"id": req_id, "done": True, "exitCode": code})


async def _handle_request(req_id: int, method: str, params: dict[str, Any]) -> None:
    try:
        if method == "bash_exec":
            await _handle_bash(req_id, params)
            return

        sub = _subcommand_registry.get(method)
        if sub is None:
            _write_line({"id": req_id, "error": f"Unknown method: {method}"})
            return

        result = await sub.handle(params)
        _write_line({"id": req_id, "result": result})
    except asyncio.CancelledError:
        _write_line({"id": req_id, "done": True, "exitCode": None})
        raise
    except Exception as e:
        _write_line({"id": req_id, "error": str(e)})


async def serve() -> None:
    loop = asyncio.get_running_loop()
    # Requests arrive as single JSON lines and can be large (write_file
    # content, before_agent_start system prompts), well past the 64 KiB
    # StreamReader default.
    reader = asyncio.StreamReader(limit=64 * 1024 * 1024)
    protocol = asyncio.StreamReaderProtocol(reader)
    await loop.connect_read_pipe(lambda: protocol, sys.stdin.buffer)

    tasks: dict[int, asyncio.Task] = {}

    while True:
        line = await reader.readline()
        if not line:
            break

        msg = json.loads(line)

        if "cancel" in msg:
            task = tasks.pop(msg["cancel"], None)
            if task:
                task.cancel()
            continue

        req_id = msg["id"]
        method = msg["method"]
        params = msg.get("params", {})

        task = asyncio.create_task(_handle_request(req_id, method, params))
        tasks[req_id] = task
        task.add_done_callback(lambda t, rid=req_id: tasks.pop(rid, None))

    for task in tasks.values():
        task.cancel()
    await asyncio.gather(*tasks.values(), return_exceptions=True)


if __name__ == "__main__":
    asyncio.run(serve())
