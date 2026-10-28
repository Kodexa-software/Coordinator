# Changelog

## 0.2.0 - 2026-10-28

The first public release, rebuilt from scratch after measuring the earlier version on real runs.

- A script schedules, merges, runs the gate and serves the live page, at no token cost. Agents run as
  separate background Claude Code sessions.
- A planner splits the request into small tasks with dependencies, file lists, model and effort.
- A hallucination officer audits the plan, and then each finished task, against everything the owner has said,
  and sends work back until it holds up.
- The owner approves the plan once. Independent tasks then build in parallel, each in its own git worktree with
  its own reviewer.
- Merge conflicts and failing gates become small fix tasks.
- Tests are off unless the owner asks for them, enforced by a hook.
- Pause, resume, plan-only runs, `add`, `tell`, `answer`, `accept`, `retry`, `stop` and `terminate`.
- Before/after screenshots on request, composed into one PNG.
- The run's knowledge stays in `<project>/.coordinator/`, so a later run can pick it up.

## 0.1

Unpublished. A single-session coordinator with lead and worker agents, one task at a time. Retired; see "How it
compares" in the README.
