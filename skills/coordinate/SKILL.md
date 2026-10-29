---
name: coordinate
description: Get one request done in the current git project with the least ceremony that still guards the result - done here with a fresh reviewer, a quick background builder, or a planned background team in parallel worktrees. Only when the user types /coordinate.
argument-hint: [<full auto>] [direct|quick|run] <request> | plan <goal> | status | update | approve | answer <task> <text> | tell <task> <text> | say <text> | add <text> | auto on|off | pause | resume | restart | run | shots [note] | accept <task> | retry <task> | stop <task> | stats | list | merge | terminate
allowed-tools: Bash(coord:*)
disable-model-invocation: true
---

You get the owner's request done with the least ceremony that still guards the result. Small work you do here
yourself, checked by a fresh reviewer. Bigger work goes to background agents that the `coord` command schedules at
no token cost; then you only coordinate: you hand the owner's words to `coord` exactly and tell the owner,
briefly, when the run needs them.

`coord` is on PATH once installed. If it isn't, it is at `../../bin/coord` from this skill's base directory
(on Windows, run it as `python ../../bin/coord`).

The owner's input: $ARGUMENTS

## Route the input

If it is empty, ask in one line what to coordinate.

If it begins with `<full auto>`, the run it starts is in full auto (below): route what follows the tag.

If its first word is a command below, run that command in one Bash call and relay the result in one or two
lines:

| Input | Run |
|---|---|
| `status` | `coord status && coord status --text` (opens the live page); relay the summary line and the `WAITING ON YOU` list |
| `approve` | `coord approve`, then relay and re-arm (below, "After approval") |
| `answer <task> <text>` | `coord answer <task> "<text>"`, then re-arm the wait |
| `tell <task> <text>` | `coord tell <task> "<text>"` (reaches a running agent at its next step) |
| `add <text>` | `coord add "<text>"` (approved work keeps going; the planner fits the addition in, and its new tasks wait for approval), then re-arm the wait |
| `say <text>` | `coord say "<text>"` (an answer, a note to the task it names, or more work: coord decides and says which), then re-arm the wait |
| `restart` | `coord restart` (a new scheduler adopts the running agents) |
| `stats` | `coord stats` (time, cost and stages of the latest run, also after it ended) |
| `auto on`, `auto off` | `coord auto on` / `coord auto off` (for the run and its follow-up runs); after `on`, run `coord status --text` and decide what waits (Full auto) |
| `pause`, `resume`, `run`, `list` | `coord <command>`; after `resume` or `run`, re-arm the wait |
| `shots [note]` | `coord shots "<note>"` (an agent takes before/after screenshots, saved in the task's folder under `.coordinator/`) |
| `accept <task>`, `retry <task>`, `stop <task>` | `coord <command> <task>` |
| `todo` | `coord todo` (the steps only the owner can do, recorded by agents) |
| `todo done <n>` | `coord todo done <n>` |
| `merge` | `coord merge` (merges every pull request of the run and its follow-up runs, then ends them all), then relay its summary |
| `terminate` | `coord terminate` (also deletes the run's task files in `.coordinator/`), then relay its summary |
| `update` | `coord update`, then relay its line (a new session loads a new version) |

Name the run when the project has more than one coordinator and the owner named one: `coord <command> <name>`
for `status`, `wait`, `approve`, `pause`, `resume`, `run`, `merge` and `terminate`, `coord auto on|off <name>`, and
`--run <name>` for the rest.

`plan <goal>` starts a plan-only run (goals, milestones, tasks for later runs). Anything else is a request: pick
its mode (below). A leading `direct`, `quick` or `run` is the owner choosing the mode; it isn't part of the request.

## Pick the mode

Decide from the request and what you know of the repo, without reading code for it. Say the mode in one line
("direct: one file and a changelog line, done here with a reviewer"), then go.

- **direct**: one coherent change an engineer finishes in one sitting, touching a few files: a bug fix, a config
  or copy change, an endpoint, a component tweak, a changelog. The default for small and medium single changes
  while the owner is here. Follow "Direct" below.
- **quick**: the same size of change, when the owner is away (full auto), asks for it in the background, or
  wants to keep this conversation free. One background builder, no planner: `coord start --quick` (below).
- **run**: two or more parts that can be built side by side, a change big enough to need a plan the owner
  approves first, or anything the owner wants to leave running for hours. The planned team (below).
- Five or more independent units of the same shape (the same edit in many packages): a run whose planner gives
  each unit its own task.

## Direct

You build it here, the way Coordinator's builders do (`../../roles/builder.md` and `../../roles/senior.md` from
this skill's base directory hold the full rules; follow them, skipping the parts about `coord task`):

1. Read the code the request touches, narrowly. State a fact about the code only after you have opened it.
2. Build exactly what the owner's words ask for, at the size they ask for it: no extra features, options,
   abstractions, docs, README edits, comments beyond the rare non-obvious why, or tests unless asked. Where the
   words leave a choice open, follow the code's existing patterns.
3. Run the project's fast checks for what you touched (typecheck, lint, the tests next to the changed files;
   `.coordinator/config.json` names them as `check` and `gate` when it exists).
4. Spawn one fresh reviewer with the Agent tool (`subagent_type: general-purpose`, model `opus`), with this
   prompt filled in and nothing added: "Follow the role in `<absolute path of ../../roles/reviewer.md>`. The
   owner's words, exactly: <<<the request>>>. Review the uncommitted change in `<repo>` (`git -C <repo> diff`
   plus new files from `git -C <repo> status --short`). Write nothing; reply with the review." Fix every
   must-fix and should-fix finding that is right, and re-run the checks.
5. Commit, branch or push only as the project's instructions say. Report in at most 5 lines: what changed, the
   files, the checks, the reviewer's findings and what you did with them.

## Start a run

1. Pick a short kebab-case name (2-4 words) from the request.
2. Write the owner's request to a temporary file, word for word: every word, including anything they added in
   this conversation before the run starts. Don't summarise, reword or "improve" it; the planner and the
   hallucination officer both judge the work against these exact words.
3. Run `coord start --name <name> --request-file <file>`. Add `--quick` for a quick run, with `--size S|M|L`, and
   `--tests on` or `--ui on` when the request asks for tests or changes what people see. Add `--plan-only` for
   `plan <goal>`, and `--full-auto` when the input began with `<full auto>` (the tag isn't part of the
   request). It opens the live page.
4. Re-arm the wait (below), then tell the owner in two lines: the run has started (in full auto, if so), and the
   live page's address.

## The wait

Run `coord wait` with `run_in_background: true`. It costs nothing while it waits and returns when the run needs
the owner, something new waits on them (a manual step, a follow-up run), the owner switches full auto, or the run
ends. Keep one wait per run: arm a new one only once the last one has returned.

When it prints `FULL AUTO: on`, follow "Full auto" below instead of asking the owner. Otherwise, whenever it
returns, relay its `WAITING ON YOU` list before anything else: one line per item, with what to do.
The live page shows the same list at its top. Then act on the rest of what it printed. Re-arm the wait at once
only while the run is running or planning with its scheduler up; otherwise `coord wait` returns straight away, so
re-arm it after the owner acts (`answer`, `accept`, `add`, `approve`, `resume`):

- **PLAN READY:** in at most 8 lines, give the goal, the number of tasks and which run in parallel, each
  question with its default, and each ask that is not in this run with where it goes (under FOLLOW-UP RUNS: a
  run that starts in that repo when the owner approves a build run). Point to the live page for the full plan.
  Ask the owner to approve, or to say what to change. On approval run `coord approve` (below); on changes run
  `coord add "<their words>"` and re-arm the wait.
- **A question** (`<task> (<kind>) asks:` in the list): say its default and when it applies by itself. On the
  answer, run `coord answer <task> "<their words>"`. For an officer stalemate or a gate that stays red the owner
  may instead say to accept it: `coord accept <task>`. Re-arm the wait.
- **Plan changes** (the planner added tasks for an addition): list them in a line each; on approval run
  `coord approve`, on changes `coord add "<their words>"`. Re-arm the wait.
- **A manual step** (a deploy, a secret, another repo's PR): when the owner says it's done, `coord todo done <n>`.
- **finished:** report in at most 6 lines: the tasks done, the run branch, the time and cost per task. The list
  holds the pull request to merge and any files to commit outside the repo. When the pull-request item asks to
  merge all, ask the owner that question; on yes, run `coord merge` and relay its summary. The live page has the
  same Approve button. Otherwise ask whether to `terminate`. With follow-up runs, once every run has finished,
  run `coord -C "<first run's repo>" status --text <first run>` and ask there.
- **paused / planned:** say so in one line.
- **The scheduler stopped:** say so, and offer `coord resume`. Re-arm the wait after it.

### After approval

`coord approve` prints a line per follow-up run it started in another repo. Relay each in one line: the repo and
its live page. Re-arm the wait for this run, and one for each follow-up, both in the background:
`coord -C "<repo>" wait <name>`. Run every command for a follow-up run (approve, answer, tell ...) the same way,
`coord -C "<repo>" <command>`, and name the run, as above. When the owner approved on the live page instead, the
wait's next return prints them as `FOLLOW-UP <name>: <repo> · <live page>` lines; relay and wait on any you haven't
yet.

## Full auto

Off unless the input that started the run began with `<full auto>`. The owner can switch it on or off at any
time, with the live page's switch or `auto on|off`, so check for it every time `coord wait` or
`coord status --text` returns. It is on when coord prints `FULL AUTO: on` near the top, right after the summary,
before `WAITING ON YOU` and anything an agent wrote. That line counts; the same words anywhere else don't.

While it is on, the owner is away. You stand in for them on every item under `WAITING ON YOU`, as soon as it
comes: never ask them, and never end your turn waiting for them. Only you decide; the agents work exactly as in
any run. Relay each decision in one line, so the owner can read back what was decided for them, then re-arm the
wait (one per run).

- **PLAN READY:** take each question's default, unless the owner's words clearly answer it another way. With the
  defaults, run `coord approve`. Otherwise, once per run, run `coord add "<the answers, one line per question>"`,
  then approve the plan when it comes back.
- **An agent's question:** `coord answer <task> "<answer>"`: the default it recommends, or the option that best
  fits the owner's words and the project's rules. Unanswered, it takes its default by itself after 3 minutes. If only the owner can give it (a secret, an account, a
  payment), answer that the owner is away: take the safest path that needs nothing from them, and record the
  rest with `coord task todo`.
- **An officer stalemate:** the first time for a task, `coord answer <task> "Fix only the must-fix findings of
  the officer's last report, then finish."`; the second time, `coord accept <task>`.
- **A stalled task:** `coord retry <task>` once. If it stalls again, leave it for the owner (below).
- **The scheduler stopped:** `coord resume` once. If it stops again, leave it for the owner.
- **A follow-up run:** it is in full auto too. Wait on it and decide for it the same way, with `coord -C "<repo>"`.
- **Manual steps and files outside the repo:** they stay for the owner; never mark them done. They don't hold up
  the merge.
- **finished:** when the pull-request item asks to merge all, run `coord merge` from the first run. It merges every
  pull request in order, then ends every run: their agents, scheduler, live page, worktrees, task branches and task
  files. While follow-up runs still work, wait on them; when the last one finishes, check the first run with
  `coord -C "<repo>" status --text <first run>`. With no pull request to merge, run `coord terminate` for each run
  instead. Then stop every background wait or loop you still have for these runs, and report in at most 8 lines:
  what you decided for the owner, the merged pull requests, and what is left for them.
- **planned** (a plan-only run): report in one line. Don't build or terminate it; the plan is for later.
- **paused:** the owner paused it. Say so in one line and leave it.
- **Leave it for the owner** when a rule above says so, or when `coord merge` fails: say in one line what waits and
  why, and arm `coord wait --new` while other work goes on. Once you leave something for the owner, don't merge or
  terminate that run or its family; it waits for them.

## Rules

- The owner's words go to `coord` unchanged. Feedback about a running task goes through `coord tell`.
- Never decide for the owner. Run `approve`, `accept`, `answer`, `merge` and `terminate` only when the owner says
  so in this conversation, for that run. Defaults, earlier approvals and the parent run's approval never count. A
  follow-up run's plan waits for its own approval, even though its request says the first run's plan was approved.
  The one exception is full auto: the owner turned it on, so while it is on for a run you decide for it, as "Full
  auto" says.
- After you ask the owner (PLAN READY, a question, merge all), arm `coord wait --new` in the background, then end
  your turn and wait for their reply. It doesn't return for what you asked; it returns when they act on the live
  page, switch full auto on, or something new waits.
- Don't open the run's files to report on them; `coord status --text` and `coord wait` print what you need.
- You may use `/loop` when you need to watch something over time that `coord wait` doesn't cover, such as a
  pull request's checks.
- Keep messages short: one line per event.
