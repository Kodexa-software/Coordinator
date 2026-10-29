# Coordinator against a plain session, the Agent tool and eforge, measured on Windows

Real runs on the founder's Windows 11 PC, 29 Oct 2026. Coordinator **0.10.3**, Claude Code 2.1.268, Python 3.14.
Two requests, each given word for word to every method, on fresh clones with a local bare `origin`. Builders ran on
Opus at high effort in every method, so this compares process, not model tier. The fixes that follow from it are in
[fixes-windows.md](fixes-windows.md); the macOS runs and their fixes are in [macos-report.md](macos-report.md) and
[fixes-macos.md](fixes-macos.md).

## Verdict

**Not a wreck, but its pipeline shape makes it 3 to 5 times slower and 2 to 3 times more expensive than one plain
session on small and medium tasks.** Output quality is good: blind judges ranked Coordinator's diff first on both
tasks, and it was the only method that shipped no regression and nothing unrequested. Everything around the output
is the problem: it did not run at all on this Claude Code until `--agents` was fixed; a one-file fix took seven
sessions and 17.5 minutes; a medium feature spent 28 minutes and $14 on planning and audits before any code, then
stalled for 2h 44m on a question about test files.

| | Small fix | Medium feature |
|---|---:|---:|
| Plain session | 3m 51s · 1.62M tokens · $1.55 | 20m 57s · 14.5M · $9.90 |
| Coordinator | 17m 32s · 5.10M · $5.85 | 64 min agent time (3h 41m wall) · 31.1M · $28.61 |
| Ratio | 4.6× time · 3.2× tokens · 3.8× cost | 3.0× time · 2.1× tokens · 2.9× cost |
| Quality (blind) | Coordinator 1st/2nd of 4, plain 3rd | Coordinator 1st of 2 |

Use a plain session with plan mode and `/code-review` for day-to-day work until the fixes land. A run with three or
more independent tasks is the only shape that can pay for the ceremony, and the fixed version should route anything
smaller to a quick mode (see fixes S1 to S3).

## What was tested

| Task | Request | Repo | Methods |
|---|---|---|---|
| **1**, small fix | Make every `gh pr` call in `bin/coord` target the `origin` remote's repository explicitly via `--repo`, derived from `git remote get-url origin`, so a run works without `gh repo set-default`. Add a 0.10.4 CHANGELOG entry. | Coordinator itself | plain session, native Agent tool (builder + reviewer subagent), Coordinator, eforge 0.8.1 |
| **3**, medium feature | Add a build version (short git hash, `dev` fallback) in three places: site footer, app Account page, `/api/health`. Regenerate OpenAPI spec and client. Follow repo conventions: i18n, RTL-safe, no hard-coded hosts. | Kodexa-Website (pnpm, TypeScript monorepo) | plain session, Coordinator (eforge and native dropped to save usage) |

Measurement: wall time from timestamps and `scheduler.log`. Tokens are input + output + cache reads + cache writes,
the definition Coordinator's live page uses. Cost is what Claude Code's JSON output or Coordinator's `tasks.json`
reported. Quality was judged blind by Opus judges given the diffs with method names replaced by letters: two judges
on Task 1, one on Task 3. Coordinator ran with `pr: false`, `push: true`, `max_parallel: 3`; gate for Task 1 was
`py_compile` plus `--help`, for Task 3 `pnpm typecheck && pnpm lint`.

## Task 1: the small fix

| Method | Wall | Tokens | Cost | Sessions | Owner stops | Blind rank (A / B) | Why |
|---|---:|---:|---:|---:|---:|---|---|
| Plain session | 3m 51s | 1.62M | $1.55 | 1 | 0 | 3rd / 3rd | Correct, but breaks ssh-alias remotes |
| Native Agent tool | 2m 57s | 1.53M | ~$1.50 | 2 | 0 | 4th / 4th | Drops the host, so GitHub Enterprise regresses |
| **Coordinator** | 17m 32s | 5.10M | $5.85 | 5 + reviewer | 1 | **1st / 2nd** | Minimal, keeps the host, safe fallback when it cannot parse |
| eforge | 12m 08s | 4.50M | $6.61 | 17 | 0 | 2nd / 1st | Correct for every URL form; adds unrequested skip paths and docstrings |

All four found all seven call sites, added the changelog entry in the existing style and bumped the plugin version
and README badge. URL parsing decided the ranking. The two fast methods each shipped one real regression;
Coordinator's review and audit stages caught theirs. The same protection costs a fraction of this when a plain
session is told to self-review or `/code-review` runs on the branch.

### Where the 17m 32s went

| Stage | Session | Time | Tokens |
|---|---|---:|---:|
| Planner | Opus high, cold | 3m 20s | 0.87M |
| Officer plan audit, round 1 (REVISE over a knowledge-base note) | Opus high, cold | 2m 55s | 0.57M |
| Planner, round 2 | Opus high, cold | 1m 00s | 0.62M |
| Officer plan audit, round 2 | Opus high, cold | 1m 38s | 0.48M |
| Owner approval | human | 0m 24s | |
| Builder with reviewer subagent | Opus high, cold | 6m 15s | 2.02M |
| Officer task audit | Opus medium, cold | 1m 59s | 0.55M |

Half the run (8m 53s, 2.5M tokens) produced a plan for a one-file change. The only revise round was about a
knowledge-base nit, not the code.

## Task 3: the medium feature

| Method | Wall | Tokens | Cost | Files | Owner stops | Outcome |
|---|---:|---:|---:|---:|---:|---|
| Plain session | 20m 57s | 14.5M | $9.90 | 34 (+228 / −5) | 0 | Complete, gate green. Added five test files, deploy-script comments and README text nobody asked for. Runs git during every build, so local dev shows a hash instead of `dev`; its git helper is imported from the site's shared module despite its own "never import from browser code" note. |
| **Coordinator** | 64 min agent time; 3h 41m wall, 2h 44m of it idle; 28m 19s to an approved plan | 31.1M | $28.61 ($14.15 before any code) | 30 (+120 / −4) | 2 | Complete, gate green. Git only in the deploy scripts, git-free resolver in `@kodexa/config`, `dev` everywhere else. Only forced test edits (three one-line additions). One unrequested README paragraph. |

Blind judge: Coordinator 4 / 5 / 4 / 4 / 4 against the plain session's 3 / 5 / 2 / 3 / 3 for correctness,
completeness, scope, quality and mergeability. Coordinator's diff ranked first.

### Where the time went

| Stage | Time | Tokens |
|---|---:|---:|
| Planner, round 1 | 11m | 5.0M |
| Officer plan audit, round 1 | 6m 14s | 2.4M |
| Planner, round 2 | 4m 16s | 5.8M |
| Officer plan audit, round 2 | 6m 40s | 2.5M |
| Owner approval | 0m 58s | |
| Builder T1 (until it asked about test files) | 4m | 1.8M |
| **Idle, question unanswered** | **2h 44m** | |
| T1 resumed, T2 to T4 built, reviewed, audited and merged | 24m | ~13M |

The second planner round alone used 5.8M tokens, more than a third of what the plain session needed for the whole
feature. T2, T3 and T4 all depended on T1, so the "parallel" stage was serial. The stall: T1's type change forced
three one-line edits in test files, the gate went red, the tests-off hook blocked the builder, and the rule "ask the
owner if an existing test breaks" turned a routine fix into a human stop that the owner's answer could not unblock
without a `coord answer`.

## Code audit

Full read of `bin/coord` (3,082 lines), `SKILL.md`, every role file, README and CHANGELOG, through six lenses:
lifecycle, feature value, tokens, prompt design, scheduler correctness and Windows. "Seen live" items happened in
these runs. The others were not re-verified by a second pass, to save usage.

### Critical

1. **Seen live. Did not run on Claude Code 2.1.268.** `--agents` was passed a file path; current Claude Code
   requires inline JSON, so every agent died in 2 s with exit 1 and 0 tokens. Fixed in commit `e8245d7` (two
   sites in `start_job`). A running scheduler keeps the old code in memory, so `coord retry` did nothing until
   `coord terminate --purge` and a new run.
2. **Seen live. Tests off + "ask the owner if a test breaks" is a guaranteed stall.** Any type change that reaches
   a test file makes the gate red, the hook blocks the builder, and the run waits for a human.
3. **Pipeline shape.** A happy-path one-task run is six or seven cold Opus sessions and two human stops. Three
   tasks is 11 top-level sessions plus 3 to 6 reviewer subagents, 17 to 23 with the officer's expected revise
   rounds. This is the same shape as the 0.1 runs that measured 212M to 371M tokens against 87M direct.
4. **Gate failure cascade.** After one gate failure, every other finished task is still squash-merged onto the
   broken run branch and each spawns its own Opus fix task; fix recursion has no cap (`integrate()` ≈ 1097,
   `add_fix()` ≈ 1066).

### High

5. **The officer gates every plan and task yet is forbidden to read code.** It audits the builder's self-report
   against a checklist; every round is a fresh Opus session, up to three rounds, and the full-auto path accepts
   eventually anyway. When the owner attends, the owner is already the scope judge.
6. **Every session re-reads the whole instruction chain "in full".** Claude Code injects it; the roles order it
   read again, plus every guide it names. In the Kodexa workspace that is the 3,300-word `.kodexa/README.md` and a
   product page, about 10 to 13K tokens per agent before any work.
7. **Workspace rules conflict with role rules.** The workspace says commit and push at every task end; the roles
   say never, and "ask the owner on any such conflict"; the officer rejects plans that do not ask. One stall
   question in every Kodexa run.
8. **No stall detection; restart duplicates agents.** A stopped fix task or a bad dependency leaves the run
   "running" forever while `coord wait` blocks. A scheduler restart wipes the agent table and relaunches agents on
   in-progress tasks without checking whether the old ones still run.
9. **Opus at high effort everywhere by default,** reviewer and officer included; `efforts.reviewer` is never
   applied (`DEFAULTS` ≈ 68).
10. **Single-threaded scheduler** runs setup, gate and push inline; the gate runs twice per task; officer audits
    consume build slots.

### Medium

- The planner must pre-resolve every path and line range so builders "should not need to search"; the officer
  makes any unresolved path a must-fix. Exploration moves into a serial Opus stage.
- The token figure on the live page counts cache reads at par with input; it scales with turns × context size, not
  with work or dollars.
- Windows: a `.cmd` shim on the spawn path goes through cmd.exe, which truncates multi-line arguments at the first
  newline and treats `&` as a separator (`claude` is an exe here, `npx` is a cmd). `os.replace` on `tasks.json`
  can fail with permission errors while a reader holds it; nothing catches that. PID reuse makes stale scheduler
  PIDs look alive. `notify()` is macOS only. `coord` was not on PATH in the Git Bash used by Claude Code.
- `coord add` drains the pipeline; a check-then-set race can start two schedulers; worktrees can be removed under
  running agents; `wip.patch` is marked applied after a failed apply.
- The planner recorded a spurious todo containing only the word "list", plus two todos that could never be done
  in this environment; each is an owner interruption.

## Alternatives

| Option | What you get | Verdict |
|---|---|---|
| Plain session + plan mode + `/code-review` | One context that knows the workspace; a plan approved in a minute; a review pass before merging. One CLAUDE.md line forbids unrequested tests and files. | **Best default.** Fastest and cheapest in every measurement. Its over-delivery on Task 3 is a prompt-rule gap, not a tooling gap. |
| Native Agent tool (builder + reviewer subagent) | Parallelism and fresh eyes inside one session. Anthropic: subagents give parallelism "but not a smarter answer". | Fine for parallel sub-jobs. Weakest Task 1 diff here, so a reviewer subagent is not a quality guarantee. |
| Anthropic's feature-dev and code-review plugins | Maintained explore-plan-build-review flow in one session, no scheduler, no worktrees. | Covers Coordinator's plan-then-build-with-review idea at none of the process cost. Try before any rewrite. |
| eforge 0.8.1 | Eleven stages, 17 agents on a small fix; most thorough Task 1 result; no human stops; 3× the time and 4× the cost of a plain session. | Works, but unmaintained since 13 Jul 2026, single maintainer, not accepting issues or PRs, Windows untested. |
| Claude Code `/batch` and agent teams | Built-in fan-out for 5 to 30 independent units, each on its own branch and PR. | The right tool for the one case Coordinator was built for. Agent teams cost about 7× a single session in Anthropic's numbers. |

Research context: Anthropic puts multi-agent setups at roughly 15× single-session tokens; a Google and MIT study
(arXiv 2512.08296) found multi-agent systems below a single agent on SWE-bench at 1.6 to 6.2× the tokens; a
code-review study found 56% of agentic review comments rejected by developers. Orchestration pays only when the
work is truly parallel and the orchestration overhead is small.

## How this squares with the macOS report

The macOS report says "keep Coordinator" because the new version beat 0.1 on two large redesigns (both PRs merged,
half the tokens). This report says "pause daily use" because on small and medium tasks the new version loses badly
to a plain session. Both are true. Coordinator's shape is built for long, parallel, unattended runs on a Mac that
stays on. Most of the founder's requests are not that. The fixes document gives the small-task mode that closes
that gap and the pipeline cuts that help every run.

## Raw data

Not in git: `C:\Kodexa\temp\coord-eval\` on the Windows PC. `results/` holds the Claude Code JSON outputs, the
eforge sqlite summary, the four Task 1 diffs as A to D and the two Task 3 diffs as X and Y with their `mapping.json`
files and judge verdicts, `audit-lenses.json` (six lens reports) and `research.json` (eleven research notes).
Coordinator's own numbers are in each clone's `.coordinator/<run>/tasks.json` and in `~/.coordinator/runs/`. The
founder's copy of this report with charts is `.kodexa/visuals/coordinator-assessment-2026-10-29.html`.

Caveats: one run per method per task. Native Agent tool cost is estimated from tokens. eforge and the native variant
were not run on Task 3; Task 3 had one judge. Coordinator's Task 3 gate passed inside its own run and was not re-run.
