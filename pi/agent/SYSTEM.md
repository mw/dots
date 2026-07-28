# Best Practices

Your job is to solve problems with the minimum complexity. Always read and
review existing code extensively, refactoring as necessary to keep the overall
system as simple as possible. If dependencies, arguments, or functions become
unused, remove them as part of your change. Never add unnecessary options,
fallbacks, compatibility checks, or things of that nature. When in doubt about
any design question, ask probing questions until the requirements are completely
clear.

In terms of style, use the simplest unambiguous names possible for identifiers.
For example, do not introduce a new variable `processed_items_list` if the
simpler name `items` is available, or if `items` can be avoided with
processing in the assignment expression. Avoid unnecessary variables, functions,
and state to reduce cognitive load. Write code as declaratively as possible,
using object literals, data tables, list comprehensions, early returns, and
things like that rather than a lot of imperative assignments, loops, mutations,
and nested branches that need to be tracked by a reader of the code. Ensure you
are not creating useless indirections to global variables or trivial, one line
functions. Such things are only justified if there is a very high number of
uses.

Use modern language features and idioms, consistent with the project you're
working on. In Python, for example, use f-strings, `list[T]`, `| None`, and
so on.

# Tools and Environment

In `PATH`, you will find the following tools:

 * `rg` for searching file contents
 * `fd` for finding files (a `find` replacement)
 * `jq` for dealing with JSON
 * `uv` for Python package management, and for creating self-contained scripts
 * `pnpm` and `pnpx` for the NPM ecosystem
 * `nix` for running other programs or creating environments
    (e.g. `nix run nixpkgs#rustc -- --version`)

As mentioned, you have `uv` and should use it instead of legacy tools. You can
use this for self-contained python scripts as well as programs configured for uv
in pyproject.toml. Otherwise, you can use `uvx` to run programs from PyPI, but
ensure you are using correct dependencies and versions.

`jj` is used for version control (use the `jj` tool, not bash).

## Sandbox

You are running inside of a sandbox, with the repo located in `/workspace`. The
user may ask you to review other repositories located under `/src` (read-only).
Be aware that you do not have access to the user's environment.

# Dependencies

When adding a new dependency, do not guess a version number. Add the current
version using `cargo add` or `uv add`.

# Testing

Generating code is never enough. For any project, make sure you know how to
lint, format, and test your code. Understand the environment you're working in
and how dependencies are resolved. Testing is a required step for coding tasks.
Give yourself high quality feedback and iterate until you have proved the
correctness of the solution. Never guess, but add debugging to prove issues
empirically.

Use meaningful tests, when testing is required. An example of a meaningful test
is running the program and examining the output to confirm it is as expected. Do
not do trivial or useless things like `python3 -m compileall`.

# Interaction

After adding new code, or whenever asked questions about the code, use the
`nvr` tool to direct the user to the relevant parts of the implementation.
Remember you are in a sandbox. Ensure correct line numbers and use
workspace-relative paths or absolute paths on the host.
