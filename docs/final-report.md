# Coordinator 0.11: the rework and the re-measurement

Measured on the founder's Windows PC, 29–30 Oct 2026, Claude Code 2.1.268. Coordinator **0.11.0** against the plain
prompt and the earlier measurements in [windows-report.md](windows-report.md). Opus at high effort everywhere, the
same request text for every method, fresh clones at the same starting commits as the first assessment. The
assessment was kept small to stay inside the founder's usage budget: weekly usage went from 49% to about 52%.

## Verdict

**Keep it, for one job: features that span several areas.** On a feature that touched the site, the app and the
API, the reworked planned run produced the best diff in two of three blind judgments and second in the third. It
passed typecheck and lint and added nothing unrequested. It cost about 1.6 times a plain prompt and took about
twice as long, with one stop for plan approval. The old version cost $28.61 and idled for hours on the same
request; the new one cost $14.41 and finished in 34 minutes.

**For small single changes, no tool beats the plain prompt.** Across five blind judgments on two small tasks, the
plain prompt ranked first every time. Coordinator's extra reviewer cost half again as much and bought nothing a
judge could see. So `/coordinate` now does small changes the way a plain session does, at the same cost, and keeps
the reviewer for risky areas only.

By the bar set in [fixes-windows.md](fixes-windows.md), the medium task had to come in under 1.5 times the plain
prompt's agent time with an equal or better rank. Run mode beats the plain prompt on rank but takes 1.8 to 2.5
times its agent time, so it misses that bar on time. Whether that trade is worth it is the founder's call: better
diffs and no babysitting, for twice the wait.

## What changed in 0.11

Everything in both fix plans is in, apart from what "Not done" lists. The main changes:

- **Three modes.** Direct, built in the session; quick, one background builder; run, the planned team. The skill
  picks one and says which.
- **The officer** checks a plan once, on Sonnet, only in full auto or for plans of more than three tasks. It no
  longer audits each task.
- **No question can stall a run.** Every question carries a default that applies by itself after 10 minutes.
  Builders may make the small test edits a type change forces.
- **No re-reading** of instruction files Claude Code already loaded. Commit and push rules no longer turn into
  questions.
- **One full gate per task,** off the scheduler's loop. A failed gate is re-run once before any fix agent starts,
  and the fix agent gets the error lines instead of the log tail. At most one fix per task, and other merges wait
  while the gate is red.
- **The scheduler adopts running agents** after a restart or an update. It also stops agents that make no progress
  and nudges builders past their time box.
- **`coord add` no longer stops the build.** `coord say` routes one message to the right place, and the live page
  has a message box for it.
- **New commands:** `coord stats` with metrics that survive `terminate`, and `coord selftest`, which runs once per
  Claude Code version so a CLI change can't silently break every agent again.
- **Fixes:** `gh --repo origin`, Windows prompts passed by file, toast notifications, and pid checks that also
  compare start time.
- **Two changes after the first medium run:** the planner went back to high effort, and the reviewer now opens every
  newly imported module to check where it may run. The first run had imported a Node-only module into Worker code.

The scheduler was tested offline with a stand-in for `claude`, at no model cost. The test covered parallel
builders, a question answered by its default, a flaky gate passing on its re-run, a restart that adopted a running
agent, a quick run and the metrics. `coord selftest` passed against the real CLI.

## Results

### Small fix: `gh pr --repo origin` in Coordinator itself

| Method | Wall | Cost | Tokens | Blind ranks |
|---|---:|---:|---:|---|
| Plain prompt, 29 Oct | 3m 51s | $1.55 | 1.62M | 3, 3 then 1, 1 |
| Coordinator 0.10.3, 29 Oct | 17m 32s | $5.85 | 5.10M | 1, 2 then 3, 2 |
| eforge, 29 Oct | 12m 08s | $6.61 | 4.50M | 2, 1 then 6, 6 |
| 0.11 direct, with reviewer | 5m 54s | $2.31 | 1.34M | 2, 3 |
| 0.11 quick | 8m 14s | $2.80 | 2.4M | 5, 4 |

The first two ranks in each row come from the 29 Oct judges, the rest from this round. The judges disagree a lot.
Quick mode shipped a real bug that its reviewer missed: an inline regex flag group that needs Python 3.11, while
Coordinator supports 3.9.

### Over-building temptation: `coord stats --json`

| Method | Wall | Cost | Blind ranks | Scope score |
|---|---:|---:|---|---:|
| Plain prompt | 2m 21s | $1.16 | 1, 1, 1 | 3 of 5 |
| 0.11 direct | 4m 52s | $2.15 | 2, 2, 2 | 5 of 5 |

The plain prompt added a changelog entry and reworded help text nobody asked for. Coordinator added nothing extra.
The judges still preferred the plain prompt's simpler code.

### Medium feature across site, app and API: the build version

| Method | Wall | Agent time | Cost | Ranks among 4 | Ranks among 6 |
|---|---:|---:|---:|---|---|
| Plain prompt, 29 Oct | 20m 57s | 21m | $9.90 | 2, 2, 2 | 6, 4, 4 |
| Plain prompt, 30 Oct | 15m 11s | 15m | $7.95 | — | 5, 2, 1 |
| Coordinator 0.10.3, 29 Oct | 3h 41m | 64m | $28.61 | 1, 1, 3 | 4, 6, 3 |
| 0.11 run, first | 32m 50s | 43m | $15.02 | 3, 4, 1 | 2, 3, 5 |
| 0.11 direct | 22m 12s | 22m | $9.54 | 4, 3, 4 | 3, 5, 6 |
| **0.11 run, after the fix** | 34m | 37m | $14.41 | — | **1, 1, 2** |

The "among 4" judges saw only the first four results, before the second round of runs existed.

Every new result passes typecheck and lint. Both plain runs added tests nobody asked for: five additions in the
first and three in the second. The first 0.11 run imported a Node-only module into Worker code. That flaw was
checked in the code and it is real. In the planned runs, the gate passed on the first try after every task, with
no questions and no stalls.

## How far to trust this

- **One run per configuration,** two for the plain medium run. The planned run after the fix was tuned on the same
  task it was then measured on, which makes it weaker evidence than a fresh task would be.
- **Blind Opus judges are noisy.** The same diffs moved two or three places between judges. One judge claimed a bug
  that the code shows isn't there, and two replies came back malformed and were dropped.
- **The plain prompt's own variance is large.** On the medium task it ranked 5th, 2nd and 1st across three judges.
- **Untested in a real run:** stall detection (no stall happened), base-branch sync with a moving base, overlap
  warnings between runs, reviewer screenshots, full auto, macOS and Linux.

## Not done

- **The Sonnet message router** from the fix plan. `coord say` routes without a model instead.
- **The website docs.** They still describe 0.10. The site picks up the version and changelog by itself.
- **A third medium or large task** that nothing was tuned on. That is the next measurement before relying on run
  mode for weeks of work.

## How to use it from today

- **A small single change:** the plain prompt, or `/coordinate`, which now does the same at the same cost.
- **A feature across several areas, or work you want to leave running:** `/coordinate` in run mode. Approve the
  plan and come back in about half an hour.
- **Quick mode:** skip it unless you're away. It had the weakest result.

Raw data, outside git: `C:\Kodexa\temp\coord-eval\v2\results\`, with run outputs, diffs and judge verdicts. The
usage script is `C:\Kodexa\temp\usage.py`.
