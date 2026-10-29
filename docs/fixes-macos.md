# Coordinator fixes (from the macOS runs, Oct 2026)

**Status:** planned, nothing started
**For:** this repo: [`bin/coord`](../bin/coord) and [`roles/`](../roles)
**Measured on:** Coordinator 0.7–0.9 runs on the founder's Mac, 27–29 Oct 2026; code checked against 0.10.3 (`8da731e`)
**Report:** https://coordinator.kodexa.workers.dev/reports/coordinator-old-vs-new/ (charts, timelines, all runs)
**Last updated:** 2026-10-29

## Goal

Better results, much faster, much cheaper. The new version already beats 0.1. Both ADP PRs merged, against none
for 0.1, at about half the tokens. Most of what remains is lost to a gate that fails without cause, work that runs
in sequence, and visual problems only the owner catches.

| Target, per comparable redesign run | Now (paint / service history) | Goal |
|---|---|---|
| Wall clock | 8.7 h / 4.3 h | −40% (≈5 h / ≈2.5 h) |
| Cost index (see the report) | 139 / 72 | −30% or more |
| Agents busy at once, on average | 1.17 / 1.35 (max 3) | 2.0 or more |
| Gate-fix tasks that change no code | 3 / 0 | 0 |
| Owner remarks after "done" that are visual | 2 / 2 | 0–1 |
| Status questions from the owner | 0 / 0 | stay 0 |

## Where the time and money went (baseline)

From the two ADP full-auto runs (`fix-paint-thickness-pr`, `service-history-redesign`):

- 34–37% of wall clock had no agent active: long builds and tests, the gate, and waiting on the owner.
- Builders spent 133 min running the full gate themselves, at 16–18 min per run with 3 builders sharing the CPU.
  The scheduler then ran it again after each merge.
- Paint T4 was one task that took 105 active minutes and cost 30 (21% of the run). Most of that was perf profiling.
- 3 gate-fix tasks took about 65 min of wall clock, and none of them changed code.
- Planning, officer audits and code review made up 35% (paint) and 42% (service history) of cost, all on Opus.
- The owner's review after "done" cost about 55 min of waiting and 3 extra tasks. 4 of the owner's 6 remarks were visual.
- The merge conflict with `master` at the end of the paint run (T8) took 24 min and cost 14.

## Bugs (wrong behaviour)

### B1. The gate fails when nothing is wrong, and the fix agent sees the wrong part of the log

- **Evidence:** paint run T2-gate, T3-gate and T4-gate passed with no code change. Two of them failed on a stale
  `src/components.d.ts`. The third failed on a slow spec, which passed on the next run.
- **Root cause:** `integrate()` (`bin/coord` ≈ line 1097) runs the gate once in the shared run worktree
  (`wt/_run`) and turns any failure straight into a fix task through `add_fix()` (≈ 1066). Gitignored generated
  files in `wt/_run` are never refreshed, because checkouts and merges don't touch them. The fix agent gets only
  `splitlines()[-60:]`, and in these failures the real error was near the top of the log.
- **Fix:**
  1. A `pre_gate` config command, run in `gate_cwd` before every gate, to delete generated files. For ADP:
     `"pre_gate": "rm -f src/components.d.ts"`. Don't use `git clean -fdX`: it also deletes the
     `node_modules` that `setup` copied in.
  2. On failure, re-run the gate once. If the second run passes, log `gate flaky after <task>` with both
     durations and carry on without a fix task.
  3. The fix task gets an excerpt, not the tail: the first 40 lines that match
     `error|Error|FAIL|✕|TS\d{4}`, each with 3 lines of context, plus the log's path. Cap it at 150 lines.
- **Acceptance:** in a run where only a generated file is stale, no fix task is created and the log says why.

### B2. The full gate runs twice for every task

- **Evidence:** 94 build and test commands inside builders took 133 minutes. The scheduler then ran the same gate again.
- **Root cause:** `first_prompt()` (≈ 850) tells every builder `Gate: <full gate> (run it from …)`.
- **Fix:** add a `check` config, a fast check for builders, falling back to `gate` when it's not set. Only the
  scheduler runs the full `gate`, after the merge. For ADP, roughly:
  `"check": "npm run typecheck && npx stencil test --spec -- --findRelatedTests $(git diff --name-only $COORD_RUN_BRANCH -- src)"`.
  Verify the exact command, and export `COORD_RUN_BRANCH` in `agent_env()`. Builder role: run `check`, and never
  run the full gate unless the knowledge file asks for it.
- **Acceptance:** builders' build and test time per task drops under 5 minutes, and gate failures stay
  scheduler-only.

### B3. Pull requests fail in repos with an `upstream` remote

- **Evidence:** kodexa-video-studio, 28 Oct ("Head ref must be a branch"); it's already on the roadmap.
- **Root cause:** every `gh pr …` call (≈ 1224, 1228, 1233, 1236, 2037, 2046, 2047) relies on `gh`'s default
  repo, which picks `upstream`.
- **Fix:** resolve `owner/name` from `git remote get-url origin` once per run, store it in `tasks.json`, and pass
  `--repo` to every `gh pr` call.
- **Acceptance:** a run in a repo whose `upstream` points elsewhere opens, edits and merges its PR on `origin`.

### B4. Every run's numbers are deleted on terminate

- **Evidence:** this comparison had to be rebuilt from 1,308 raw transcripts. `finish_job()` already
  records `minutes`, `tokens` and `cost` per task, but `cmd_terminate()` (≈ 1974) deletes the run folder.
- **Fix:** before deleting, append one JSON line to `<project>/.coordinator/metrics.jsonl` (that file stays, like
  `config.json`). Include the run, version, start and end, status, PR URL and state, lines added and deleted,
  owner actions and full-auto on or off. Per task: id, type, role, model, effort, size, minutes, tokens, cost,
  audit rounds, fix kind and parent. Per gate: task, seconds, pass or fail, flaky. Don't store the owner's words.
  Add `coord stats [--compare <run>]` to print a run, or two runs side by side.
- **Acceptance:** after `terminate`, `coord stats` prints the run's phases, cost and gate times.

### B5. Two runs on the same files only meet at the end

- **Evidence:** service history (#21) merged first. The paint run then needed T8, a merge of `master` with
  conflicts in the shared tabs and table, which took 24 min and cost 14.
- **Root cause:** `next_jobs()` (≈ 1265) checks `overlap()` only between tasks of the same run. The run branch
  is never brought up to date with the base branch while the run works.
- **Fix:**
  1. At plan time, list other open runs in the same project whose task `files` overlap this plan's. Show it in
     the plan card and the officer's plan audit, and let the owner choose: wait, go ahead, or merge one run first.
  2. After each task merges, fetch the base branch. If it moved, merge it into the run branch in `wt/_run`
     before running the gate. A conflict becomes a small fix task straight away, while it's still small.
- **Acceptance:** two runs that touch the same file get a warning before approval, and a base-branch change
  shows up as a small merge task within one task of landing.

## Quality gaps (the work is right but needs the owner to finish it)

### Q1. Visual problems are found by the owner, after "done"

- **Evidence:** a header title that wasn't centred and an active-tab underline that didn't span (paint). A page-size
  dropdown that looked wrong outside Safari, and a select that was too tall (service history). These needed 3 extra
  tasks and two review rounds.
- **Root cause:** screenshots are opt-in. `shoot()` (≈ 2827) uses `--browser chromium` only. The reviewer and
  the officer aren't required to look at screenshots of UI tasks.
- **Fix:**
  1. For every task with `ui: true`, the builder takes after-shots, plus before-shots when it changes an existing
     component. They're taken at 390 and 1280 px, in light and dark, and in Chromium and WebKit (add
     `shots.browsers`).
  2. The reviewer role opens every after-shot and checks alignment, overflow and spacing, and that the change
     matches the design language. A visible defect is a must-fix.
  3. The officer's task audit includes the shots.
- **Acceptance:** a run like these two leaves at most one visual remark for the owner.

### Q2. Plans chain tasks that could run side by side

- **Evidence:** service history ran T3 → T4 → T5 → T6 in sequence, with 1.35 agents busy on average out of 3.
  Paint averaged 1.17.
- **Root cause:** `roles/planner.md` (line 45) says to depend only on what's needed, but nothing measures or checks it.
- **Fix:**
  1. The planner adds a "wave" column to the plan table and states the critical path and the expected number of
     agents busy at once.
  2. Prefer splitting by file or area over splitting by step. For example, lay out the panel, the drawer and the
     pager in parallel against an agreed component contract, then add one integration task.
  3. The officer's plan audit sends back plans whose critical path is longer than `ceil(tasks / max_parallel) + 1`
     without a stated reason.
  4. `coord status` shows planned versus actual parallelism.
- **Acceptance:** a redesign of this size plans for 2 or more agents at once and runs at 1.8 or more.

### Q3. Tasks grow far past the 30–45 minute rule

- **Evidence:** paint T4 ran 105 active minutes and about 2.4 hours of wall clock; service T3 ran 75 minutes of wall clock.
- **Root cause:** `planner.md` (line 43) asks for 30–45 minute tasks. Nothing checks it during the build.
- **Fix:**
  1. Time-box each task by size (S 20, M 40, L 60 minutes).
  2. At 1.5× its box, the scheduler sends the builder a `tell`: finish what's coherent, write `changes.md`, and
     record what's left with `coord task followup`.
  3. Perf measuring and profiling become their own task, on Sonnet with medium effort and a fixed budget, never
     part of a build task.
- **Acceptance:** no build task goes past 1.5× its box without a split.

### Q4. The planner reads large inputs itself

- **Evidence:** the paint planner read the old 0.1 session and PR #19 on Opus, taking 38 min and costing 19
  (14% of the run).
- **Root cause:** `planner.md` (line 33) suggests `coord-briefer`, but nothing enforces it.
- **Fix:** in the PreToolUse hook (`_hook`), stop planner and builder `Read` calls on files over 256 KB, and on
  any `*.jsonl` transcript. The message says to use `coord-briefer` with the question.
- **Acceptance:** planner cost on a "fix this earlier work" request is under 8.

## Cost (same quality for less)

### C1. Opus at high effort for every audit and review

- **Root cause:** `DEFAULTS` (≈ line 68) sets `reviewer` and `officer` to `opus`, with no separate model for task
  audits.
- **Fix:** add `models.officer_task = "sonnet"` and use it in the audit launch (≈ 944). Set `models.reviewer =
  "sonnet"`, and keep Opus for plan audits and for tasks the planner marks `L`. Keep the planner on Opus, at
  medium effort when the plan has 4 tasks or fewer.
- **Expected:** −15 to −20% of run cost. Check on the next two runs that the officer still catches scope drift.

### C2. Every officer round starts a fresh session

- **Evidence:** 29 officer sessions across the two ADP runs, including 12 plan rounds. Each one reloads the
  instructions, plan and briefs from scratch.
- **Root cause:** the audit launch (≈ 936–949) always uses a new `--session-id`.
- **Fix:** from round 2, `--resume` the previous round's session. Tell it to re-check only the last report's
  findings and what changed since (`git diff` for tasks, the plan's diff for plans).
- **Expected:** a fraction of the cost per later round, and faster rounds.

### C3. Small findings cost a whole extra round

- **Fix:**
  1. Add an `approve-with-notes` verdict. Nits go to the PR writer's notes or to a final polish task, not back to the builder.
  2. Lower task-audit `max_rounds` from 3 to 2.
  3. Plan audits stay at 3.

## Already fixed (no action)

| Problem | Fixed in |
|---|---|
| The lead session held the whole run, compacted, and agents died with it (0.1) | 0.2 scheduler and separate sessions |
| The owner had to keep asking for status | 0.2–0.6: live page, `coord wait`, notifications, waiting list |
| Scope drift (the accessories rework, the 9k-line diff) | 0.2 officer audits |
| Project rules ignored (icons, tests in `ADP.TestData`) | 0.4.0 project instructions first, 0.3.0 tests-off hook |
| Comment bloat | 0.8.0 senior-engineer role |
| Only the first prompt acted on | 0.5.0 additions re-planned, follow-up runs |
| Robotic PR descriptions | 0.9.0 → 0.10.3 |
| Uncommitted `.gitignore` edit diverged `main` | 0.4.2 |
| A second PR for the same branch | 0.6.0 |
| "Idle" read as done | `coord wait` and the status in `tasks.json` |

## Order of work

| Phase | Items | Why first |
|---|---|---|
| 1. Measure | B4 | Every later change needs before and after numbers |
| 2. Stop the waste | B1, B2, B3 | Small and safe in `bin/coord`; about 3 hours saved across the two ADP runs |
| 3. Cheaper | C1, C2, C3 | Config and launch changes; −20 to −30% cost |
| 4. Faster | Q2, Q3, Q4 | Planner and officer role changes, plus the scheduler time-box |
| 5. Better | Q1, B5 | Screenshots in review and run overlap; removes most owner rounds |

Release each phase as its own minor version (0.11.0 …) with a CHANGELOG entry, the same way as earlier releases.

## How to check it worked

- After each phase, run the next comparable ADP vehicle-lookup panel redesign in full auto, and compare
  `coord stats` against the baseline table above.
- The phase is done when its targets hold on two runs.
- Keep the officer catching scope drift: no run may grow past what the owner asked for.

## Not in this plan

- Website items (`WEBSITE_DEPLOY_TOKEN`, Safari video `Range` support) belong to the website repo.
- Windows: these runs were all on macOS. Check on Windows that `pre_gate` and `check` run in Git Bash.
