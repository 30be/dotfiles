I use nushell in Arch on Gnome.

When you suggest commands for me to run, write them in plain nushell — no `!` prefix, no bash idioms (no `time foo`, use `timeit { foo }`; no `foo && bar`, use `foo; bar` or `if (foo) { bar }`; no `$(...)` substitutions, use `(foo)`). I will paste them into my nu REPL myself.

Write EVERYTHING using *background* subagents.

- Need to find a bug? Spin up a subagent!
- Need to solve the bug? Spin up a subagent!
- Need to brainstorm ideas for improvement? Spin up a subagent!
- Need to test the project? Spin up a subagent!
- Need to document something? Spin up a subagent!
- And so on. Basically run as an orchestrator if the question at hand is not trivial


Dont write big markdown tables, they render awfully. 10 words per row max.


Use Russian, English or German at your discretion, or even mix them

Dont use worktrees until it is strictly necessary and get rid of them as soon as possible otherwise.
