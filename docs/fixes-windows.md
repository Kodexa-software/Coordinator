# Coordinator fixes (from the Windows comparison, Oct 2026)

**Status:** planned, nothing started except P0
**For:** this repo: [`bin/coord`](../bin/coord), [`roles/`](../roles), [`skills/coordinate/SKILL.md`](../skills/coordinate/SKILL.md), the live page
**Measured on:** Coordinator 0.10.3 against a plain session, the Agent tool and eforge, Windows 11, 29 Oct 2026
**Report:** [windows-report.md](windows-report.md)
**Companion:** [fixes-macos.md](fixes-macos.md) covers the gate (B1, B2), metrics (B4), run overlap (B5), screenshots
(Q1), parallel plans (Q2), time boxes (Q3), big inputs (Q4) and cheaper audits (C1 to C3). This document does not
repeat those. Where an item here touches one of them, it says so.
**Last updated:** 2026-10-29

## Goal

Better output, much less time, much less cost, on every task size. Today Coordinator wins on quality and loses on
everything else. The macOS runs show it is already the right tool for long, parallel, unattended work. The Windows
runs show it is the wrong tool for the small and medium requests that make up most days. The plan: cut the fixed
ceremony that every run pays, add a quick mode so small tasks cost what a plain session costs, and let the owner
steer a running run from the live page instead of waiting for it to stop.

| Target | Now | Goal |
|---|---:|---:|
| Small fix (Task 1 shape): wall / tokens / cost | 17m 32s / 5.1M / $5.85 | ≤ 6 min / ≤ 2.2M / ≤ $2.20 (plain session was 3m 51s / 1.6M / $1.55) |
| Medium feature (Task 3 shape): agent time / tokens / cost | 64 min / 31.1M / $28.61 | ≤ 30 min / ≤ 16M / ≤ $13 |
| Time from `start` to first builder, medium feature | 28m 19s | ≤ 6 min |
| Owner stops per run, attended mode | 1 to 2 plus questions | 1 (plan approval) and 0 on quick runs |
| Idle time waiting on an unanswered question | unbounded (2h 44m seen) | 0: no question blocks a run for more than 10 min |
| Blind quality rank against a plain session | 1st | stays 1st |

## Where the time and money went (baseline)

From the two Windows runs (`gh-origin-fix`, `build-version`) and the code audit:

- Planning and plan audits were 51% of the small run's time and 44% of the medium run's agent time: 8m 53s / 2.5M
  and 28m 19s / 15.8M. The medium run's second planner round alone was 5.8M tokens.
- Every stage is a cold `claude -p` session. A one-task run is seven sessions; each one re-reads the instruction
  chain and, in the Kodexa workspace, a 3,300-word README before any work (10 to 13K tokens per agent).
- The officer cannot read code, so its task audit (about 2 min and 0.5M per task) checks a self-report against
  rules the hook and the reviewer already enforce.
- The medium run idled 2h 44m on one question. The question had a recommended default in the plan.
- T2 to T4 depended on T1, so the parallel stage was serial. Three builders, three reviewers and four officer audits
  took 24 minutes after the answer.
- The installed version could not start a single agent (P0 below). A run that cannot start costs the owner the most.

## P. Pipeline: pay for ceremony only when it buys something

### P0. `--agents` must be inline JSON (done)

- **Evidence:** every agent exited in 2 s with "Invalid --agents configuration: invalid JSON" on Claude Code 2.1.268.
- **Fix:** done in `e8245d7`: both launch sites in `start_job` pass `(r.brain / "agents.json").read_text()`.
  Release it as 0.10.4 together with B3 (`--repo` for `origin`; the implementation Coordinator produced in the eval is
  on branch `coord/gh-origin-fix` in `C:\Kodexa\temp\coord-eval\t1\coord`).
- **Also:** the scheduler keeps the code it started with. `coord update` and `coord retry` should warn when
  `bin/coord` on disk is newer than the running scheduler, and offer `coord restart`.
- **Acceptance:** a fresh install on Claude Code 2.1.268 runs the planner.

### P1. No plan audit when the owner attends

- **Evidence:** Task 1: two officer plan rounds, 4m 33s, 1.05M, one REVISE over a knowledge-base note. Task 3: two
  rounds, 12m 54s, 4.97M. The owner then approved the plan anyway.
- **Root cause:** the audit after `coord task done` on T0 (≈ 2284) runs regardless of `full_auto`.
- **Fix:**
  1. Attended runs (`full_auto` false): skip the officer. The planner ends with a self-check section in `plan.md`
     ("Every file path exists: yes. Nothing outside the request: yes. Questions have defaults: yes.") and the plan
     card shows it. The owner is the scope judge.
  2. Full-auto runs: keep the officer, one round (`max_rounds` 1 for plans). A second REVISE becomes an owner
     question with the officer's text as the default-accept note, not another planner session.
  3. Never re-plan over a nit: the officer's REVISE must name a file, a task or a request sentence it violates.
     Anything else is `approve-with-notes` (C3 in the macOS plan) and goes into the plan card.
- **Expected:** −4 to −13 min and −1 to −5M tokens before the first builder, every attended run.
- **Acceptance:** an attended run reaches "waiting on you: approve the plan" with exactly one planner session.

### P2. One planner session, resumed, never cold

- **Evidence:** Task 3's second planner round was a fresh Opus session that re-read everything: 5.8M tokens for a
  revision.
- **Fix:** every later planner round, and every "owner answered a plan question" re-plan (≈ 1600 to 1608, 1826 to
  1847), uses `--resume` on the first planner's session with only the delta ("the officer said X", "the owner
  answered Y"). Same for officer rounds (C2 in the macOS plan).
- **Expected:** later rounds at a tenth of the first round's tokens.
- **Acceptance:** `scheduler.log` shows one planner session id per run.

### P3. Drop the per-task officer; the reviewer reads the diff

- **Evidence:** 0.55M and 2 min per task on Task 1; 0.43 to 0.54M per task on Task 3; it found nothing the reviewer
  and hook had not already enforced. By its own role it does not read code.
- **Fix:**
  1. Remove the officer task audit from the default pipeline. The builder's reviewer subagent gets the officer's
     scope checklist appended to its brief: "Everything in the diff traces to a sentence in the request or the task
     brief; list anything that does not as a must-fix."
  2. Keep an optional `audits.tasks: true` config for full-auto runs on risky repos. When on, it runs on Sonnet,
     reads `git diff` (not `changes.md`), one round.
- **Expected:** −2 min and −0.5M per task; one fewer process per task.
- **Acceptance:** a three-task attended run spawns planner + 3 builders + writer, nothing else.

### P4. Stop the "read in full" re-reads

- **Evidence:** every role tells the agent to read the project-instruction chain again "in full" plus every guide it
  names. Claude Code already injected the chain. In the Kodexa workspace this adds the README and a product page
  per agent, three agents per task.
- **Fix:**
  1. Delete the "read these files in full" lines from `planner.md`, `builder.md`, `officer.md`, `reviewer.md` and
     `senior.md`. Replace with: "Your project instructions are already loaded. Read a guide only when a task brief
     names it."
  2. The planner lists per task the one or two guide files that task needs, under `Read these`, and nothing else.
  3. Builders currently get the project CLAUDE.md twice (`--add-dir` plus the auto-load); pass `--add-dir` only for
     directories outside the repo.
- **Expected:** −10 to −13K tokens per agent before work; faster first turns.
- **Acceptance:** a builder's first tool call is on a file from its brief, not on `CLAUDE.md` or `README.md`.

### P5. No question blocks a run

- **Evidence:** the 2h 44m idle on Task 3. The plan had "default: yes" on that question.
- **Fix:**
  1. Every agent question carries a `default` and a `deadline` (10 min attended, 0 in full auto). The scheduler
     answers with the default at the deadline and logs it; the live page shows "answered by default" with an undo.
  2. The builder brief says: "If the plan's question list already gives a default for this, act on it and record it
     in `changes.md`; do not ask again."
  3. `coord wait` returns on a question only if `deadline` is more than 2 minutes away; otherwise it just prints it.
- **Expected:** idle time bounded at 10 min per question.
- **Acceptance:** a run with an unanswered question still finishes.

### P6. Builders may make type-only edits to tests

- **Evidence:** the tests-off hook blocked three one-line additions that the gate required.
- **Fix:** the hook allows edits to existing test files when the diff for that file adds or changes ≤ 5 lines and
  adds no `it(`, `test(`, `describe(` or new file. Larger test edits still need the owner. The builder records
  every test edit in `changes.md` under "Forced test edits" so the reviewer sees them.
- **Acceptance:** Task 3 runs end to end with no question.

### P7. Resolve project-rule conflicts from the project, not the owner

- **Evidence:** the Kodexa workspace says commit and push at every task end; the roles say never; the officer
  rejects plans that do not ask. A stall question in every Kodexa run.
- **Fix:** the role rule becomes "commit on the task branch as the project instructions say; Coordinator pushes the
  run branch; never push a task branch to a shared branch yourself." Delete "ask the owner on any such conflict"
  from `senior.md` and `officer.md`; the project instructions win (0.4.0 already says so).
- **Acceptance:** a Kodexa run reaches its first builder with no owner question.

### P8. Models and effort by stage

- **Fix:** `DEFAULTS` (≈ 68): planner Opus medium for plans of ≤ 4 tasks, high above that; builder Opus high for
  M and L, Sonnet high for S; reviewer Sonnet medium; officer (full auto only) Sonnet medium; writer Sonnet low.
  Apply `efforts.reviewer`, which is read but never used. (C1 in the macOS plan proposes the same for audits.)
- **Expected:** −30 to −40% cost on a run of mixed sizes; no measured quality loss is expected for reviewer and
  writer, check it on the next two runs.

### P9. Scheduler: gate off the loop, run once, stall detection, restart dedupe

- **Fix:**
  1. The gate, `setup` and `push` run in a worker thread; the loop keeps polling and serving `wait`.
  2. One gate per task (B2 in the macOS plan gives builders a fast `check` instead).
  3. Stall detection: a task whose agent produced no transcript bytes for `stall_minutes` (default 15) is marked
     `stalled`, its agent is killed, and the owner sees it; in full auto it is retried once with `--resume`.
  4. On a gate failure stop merging further tasks onto the run branch until the fix task passes; cap fix tasks at
     one per task, then ask.
  5. On restart, read `agents.json` and check PIDs (with start time, not PID alone) before relaunching anything.
  6. Officer or review sessions never consume `max_parallel` build slots.
- **Acceptance:** a killed builder shows as `stalled` within 15 min; a restarted scheduler launches no duplicate.

### P10. Report cost, not cache-inflated tokens

- **Fix:** the live page, `coord status` and `coord wait` show `cost` (from `total_cost_usd`) first and tokens as a
  secondary figure; the token figure uses the macOS report's weighted index (input ×1, cache write ×1.25, cache read
  ×0.1, output ×5). Feeds B4's `metrics.jsonl`.

## S. Small tasks: a quick mode that costs what a plain session costs

The founder's request: make Coordinator good for small tasks too. The honest limit first: a background run can
never beat a plain session's 3m 51s on a one-file fix, because the plain session already has the owner's context
loaded and nobody has to hand anything over. The goal is to be within two minutes of it, to keep the things the plain
session lacks (scope hook, reviewer, live page, PR), and to make Coordinator choose the right mode itself.

### S1. Size the request before planning, and pick the mode

- **Fix:** `/coordinate` (the owner's own session, which already knows the request and the repo) classifies the
  request before `coord start`:
  - **quick**: one coherent change an engineer would do in one sitting: a bug fix, a config or copy change, one
    endpoint, one component tweak, a changelog. Signals: one or two files named or implied, no new module, no
    migration, no design decision.
  - **run**: anything that splits into two or more tasks that could proceed independently, or needs a design
    decision the owner should approve.
  - **batch**: five or more independent units (files, components, endpoints) with the same shape; suggest
    Claude Code's `/batch` instead and stop.
  The session states the mode in one line ("quick: one builder, no plan") and starts it. The owner can force a mode
  with `coord start --quick` or `--plan`.
- **Acceptance:** Task 1's request is classified `quick`; Task 3's is `run`.

### S2. Quick mode: one builder, no planner, no officer

- **Flow:** `coord start --quick` creates the run branch and one worktree, writes the request as the single task
  brief (T1, size S), and launches one builder immediately. The builder:
  1. writes a five-line "intent" into `tasks.json` before touching code (files it will change, what it will not do),
     which the live page shows as the plan card; the owner can `tell` it to stop or adjust, but nothing waits;
  2. does the change under the usual hook (scope, tests off with P6, project rules);
  3. runs the fast `check` (B2), not the full gate;
  4. spawns the reviewer subagent on the diff with the scope checklist (P3);
  5. writes `changes.md` and the PR body itself (no writer session);
  6. commits. The scheduler merges, runs the full gate once, pushes and opens the PR.
  Model: Sonnet high by default for `quick`, Opus high when the request names a risky area (data model, money,
  auth, concurrency) or the owner passes `--opus`.
- **Expected:** builder 4 to 6 min, scheduler 1 min; about 1.8 to 2.5M tokens, $1.50 to $2.50. Within two minutes
  of a plain session, with a reviewer, a hook, a PR and a live page the plain session does not have.
- **Acceptance:** Task 1 in quick mode finishes in ≤ 6 min with a diff the blind judges rank no lower than today's.

### S3. Inline edits for the smallest requests

- **Idea:** some requests are smaller than a run: rename a label, bump a version, fix a typo in three places. For
  these, `/coordinate` should not spawn anything. The skill answers: "This is a two-line change; I will do it here
  on a branch and open the PR" and does it in the owner's session with the same scope rules, then records it in
  `metrics.jsonl` as `mode: inline` so the stats show how much work never needed a run. `coord` gets a `coord inline
  <branch>` helper that creates the branch, commits, pushes and opens the PR from the session's working tree, so the
  session still gets Coordinator's PR body and metrics.
- **Acceptance:** a one-line copy fix costs under one minute and one session.

### S4. Small tasks inside a run skip the ceremony too

- **Fix:** tasks the planner sizes `S` run the quick-mode builder (Sonnet high, `check` not gate, reviewer in-
  session, no officer, no separate writer notes) even inside a multi-task run. Today Task 3's three S tasks each
  got an Opus builder, a reviewer and an officer.
- **Expected:** on Task 3, T2 to T4 drop from about 8 min and 2.3 to 5.8M each to about 4 min and 1M each.

## L. Steer a running run from the live page

The founder's second request: chat with the Coordinator on the live page, send new requirements at any moment, and
have it adapt fast. The pieces mostly exist (`tell`, `answer`, `add`, owner notes, the PreToolUse hook). What is
missing is a single inbox, a router, and a delivery path into running agents that does not wait for them to stop.

### L1. One chat box, one inbox

- **Fix:** the live page gets a message box (and `coord say "<text>"` for the terminal). Every message is appended
  to `owner_notes` in `tasks.json` with a timestamp, the run's current phase and the task the owner had selected on
  the page, if any. The page shows the thread like a chat: the owner's messages, the router's one-line reply ("sent
  to T2's builder", "added as T5 after T3", "re-planning T4"), and agent questions and answers in the same stream.
  Nothing else changes in storage; the thread is the existing `owner_notes` plus the question list.

### L2. The router: decide what a message is, in seconds, without Opus

- **Fix:** the scheduler handles each new message in order:
  1. **Answer.** If a question is pending and the message is for that task (selected on the page, or the only
     pending question), it is the answer. No model call.
  2. **Steer.** If the message names a running task, or the planner's `files` for exactly one running task overlap
     the paths or words in the message, it goes to that builder (L3). No model call.
  3. **Everything else** goes to a Sonnet-medium router session (resumed across messages, so it keeps the run's
     context) with the request, the plan table and the message. It returns one of: `steer <task>`, `add <brief>
     after <deps>`, `rescope <queued task> <new brief>`, `replan` (only when the message changes the goal), `note`
     (information only; appended to every future brief), `stop <task>`. It writes the change to `tasks.json`
     through the existing commands (`task add`, `task edit`, `tell`) and posts its one-line reply in the thread.
  A `replan` is the only outcome that spawns a planner, and it uses P2's resumed planner session. In full-auto runs
  the router acts; in attended runs it acts for `steer`, `note`, `answer`, and shows a one-click confirm for `add`,
  `rescope`, `replan` and `stop`.
- **Expected:** a message is acted on within one scheduler poll (2 s) for answers and steers, and within about 30 s
  for routed messages.

### L3. Delivery into a running agent, at its next tool call

- **Root cause today:** `tell` writes a note the agent sees only when it finishes or when the owner resumes it.
- **Fix:** the PreToolUse hook (`coord _hook`) already runs on every tool call of every agent. Give it a second job:
  if the task has undelivered owner messages, return them as additional context in the hook's output ("Owner, 23:12:
  also rename the field in the admin table. Adjust your plan; do not start over.") and mark them delivered. The agent
  sees the message before its very next action, mid-task, with no restart and no lost context. The builder role
  gets one paragraph on how to take a steer: re-read its intent, update `changes.md`'s "Not in this task" if the
  scope changed, and continue.
- **Acceptance:** a `say` to a running builder shows up in that builder's transcript within one tool call.

### L4. New requirements change the plan without a cold re-plan

- **Fix:** `add <brief>` from the router goes straight into the plan as a new task with dependencies the router
  states, sized by the router, with the quick-mode builder when `S`. Queued tasks get `rescope`d by editing their
  brief in place; running tasks get a `steer`. Only a message that changes the goal of the run ("actually do this
  for the mobile app, not the site") triggers `replan`, on the resumed planner, and the owner approves only the
  changed rows. Today `coord add` drains the pipeline and re-runs planning and audit from cold.
- **Acceptance:** "also add the version to the admin footer" during Task 3 becomes T5 within a minute and runs in
  parallel with whatever is queued; no running builder is interrupted.

### L5. The live page shows what each agent is doing right now

- **Fix:** the conversation view already exists. Add a one-line "now" per task from the agent's latest tool call
  (file or command, trimmed), the elapsed time against its time box (Q3), and the undelivered-message count. This is
  what makes steering feel fast: the owner sees the moment a builder goes off course and says so.

## W. Windows parity

### W1. `.cmd` shims and newlines

- **Fix:** `which()` resolves `claude`, `gh`, `npx` and `pnpm` to their `.exe` or `.cmd`; when the result is a
  `.cmd`, spawn through `cmd.exe /d /s /c` with the argument list quoted by `subprocess.list2cmdline` and never pass
  an argument containing a newline or `&` on the command line: write prompts to a file and pass `--append-system-
  prompt-file` where supported, or pipe them on stdin.

### W2. `tasks.json` readers and PermissionError

- **Fix:** every reader opens under the same `locked()` the writers use, and `edit()` retries `os.replace` up to 20
  times with 50 ms sleeps on `PermissionError`. `_hook` and `wait` catch it and retry instead of dying.

### W3. PID reuse

- **Fix:** store the process start time next to the PID in `run.json` and `agents.json`; `alive()` compares both.

### W4. Notifications and PATH

- **Fix:** `notify()` uses a PowerShell toast on Windows (`[Windows.UI.Notifications.ToastNotificationManager]`) and
  `notify-send` on Linux; `install.ps1` verifies `coord` resolves in Git Bash (`where coord` and `bash -lc 'command
  -v coord'`) and prints the fix if not.

## What not to change

- The task store, locking, worktrees and squash-merge flow: sound, measured, keep.
- The scope hook and tests-off default (with P6): the reason Coordinator's diffs rank first.
- The reviewer subagent: cheap and it catches regressions the fast methods shipped.
- The live page and `coord wait`: the macOS report shows they removed every "status?" message.

## Order of work

| Phase | Items | Why | Check |
|---|---|---|---|
| 0. Ship what is done | P0, B3 as 0.10.4 | Nothing runs on current Claude Code without it | fresh install runs |
| 1. Stop the stalls | P5, P6, P7, P9.3 to P9.5 | Unbounded idle is the worst number in the report | Task 3 finishes with no question |
| 2. Cut the ceremony | P1, P2, P3, P4, P8, P10 | −40 to −55% time and tokens on attended runs | Task 3 ≤ 30 min agent time |
| 3. Quick mode | S1, S2, S4, then S3 | Makes Coordinator usable for the common case | Task 1 ≤ 6 min, rank unchanged |
| 4. Steering | L1, L3, L2, L4, L5 | Turns "wait for it to stop" into "talk to it" | a steer lands within one tool call |
| 5. Windows | W1 to W4 | The founder's main machine | a run on Windows needs no manual PATH or notification work |

Phases 1 and 2 are mostly deletions in roles and a few branches in `bin/coord`. Phase 3 is one new command and one
role variant. Phase 4 is the one piece of real new code (router and hook delivery). Release each phase as a minor
version with a CHANGELOG entry, and re-run Task 1 and Task 3 from `C:\Kodexa\temp\coord-eval\` after each phase with
`coord stats` (B4) so the before and after numbers come from the same requests.

## How to check it worked

- Re-run the two Windows requests and the next ADP redesign after each phase; compare against the baseline tables
  in both reports.
- Quality gate: a blind judge on the new diff against the saved baseline diffs in `results/`; the rank may not drop.
- The project is worth keeping if, after phase 3, Task 1 is within two minutes and 40% of the tokens of a plain
  session, and Task 3 is under 1.5× a plain session's agent time with the same or better rank. If not, archive it
  and keep the hook and the reviewer brief as a plain-session plugin.
