# Changelog

## 0.4.0 - 2026-10-28

- The project's instructions come first. Every agent loads the same `CLAUDE.md`, `AGENTS.md` and `.claude/rules`
  files the owner's own session would, including the folders above the project and uncommitted edits, and is
  told they win over its role. Required guides are read in full when the project says so.
- Knowledge files the project's rules keep outside the repo can be planned as tasks (`--external`) and are updated
  in place; `coord status` lists them.
- One commit per task on the run branch, with the task's title as the whole message, so runs follow each
  project's commit conventions.

## 0.3.0 - 2026-10-28

- Coordinator is now a Kodexa project: github.com/Kodexa-software/Coordinator.
- `.coordinator/` is added to the project's `.gitignore` automatically; `"gitignore": false` turns that off.
- Design languages: when a request involves UI, the planner asks which one to follow (the project's own,
  Impeccable's, or another), records it, and every UI task, its reviewer and the officer follow it. Impeccable's
  UI-craft references are bundled under Apache 2.0.
- `coord map`: a project map in `.coordinator/map/`, built with the System map method of Interpretable Context
  Methodology (bundled from icm-architect under MIT). Planners read it before the code.
- `.coordinator/AGENTS.md`: a generated entry file that routes to the config, the map and every run.
- Pushes after every merged task, with a live draft pull request (on by default).
- Tests are off unless the owner asks, enforced by a hook. The owner's later additions and answers count as their
  words for the planner and the officer.

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
- The run branch is pushed after every merged task, and a draft pull request shows the full request, the plan
  and every task, updated live. `"push": false` keeps a run local.
- Tests are off unless the owner asks for them, enforced by a hook.
- Pause, resume, plan-only runs, `add`, `tell`, `answer`, `accept`, `retry`, `stop` and `terminate`.
- Before/after screenshots on request, composed into one PNG.
- The run's knowledge stays in `<project>/.coordinator/`, so a later run can pick it up.

## 0.1

Unpublished. A single-session coordinator with lead and worker agents, one task at a time. Retired; see "How it
compares" in the README.
