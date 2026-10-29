# Changelog

## 0.11.0 - 2026-10-30

Reworked after two measured assessments: Coordinator's diffs ranked first, but it took 3 to 5 times as long and
2 to 3 times the cost of a plain session on small and medium work, and stalled for hours on one question.

- Three modes, picked by `/coordinate` and named in one line: **direct** (a single change built in your session,
  then checked by a fresh reviewer), **quick** (`coord start --quick`: one background builder, no planner) and
  **run** (the planned team).
- The officer checks a plan once, and only in full auto or for plans of more than three tasks, on Sonnet. A
  must-fix names the sentence, file or task it breaks; `notes` approves with should-fix items. It no longer audits
  each task: the reviewer checks that everything in the diff traces to your words.
- No question blocks a run: every agent question carries a default, which applies by itself after 10 minutes (3 in
  full auto). Builders may make the small test edits a type or name change forces, and list them.
- The project's rules settle commit and push: Coordinator's commit and push of the run branch meet them, so agents
  no longer ask. Agents don't re-read instruction files Claude Code already loaded, and builders skip the
  orientation reading the planner already did.
- The gate: builders run a fast `check`; the scheduler runs the full `gate` once per task, off its loop, after a
  `pre_gate` command, re-runs it once before blaming the code, and hands a fix agent the error lines, not the tail.
  One fix per task, other merges wait while the gate is red, and a failure the run didn't cause is recorded for you
  instead of looping. The base branch's new commits merge into the run branch after each task.
- The scheduler adopts running agents after a restart or an update (pid and start time), so nothing is lost or
  started twice; it restarts itself when `coord` changes. One scheduler per run, held by a lock. Agents with no
  progress for 30 minutes are stopped and resumed once; builders past 1.5 times their time box are told to wrap up
  and `coord task rest` what is left.
- `coord add` no longer stops the build: approved work keeps going and only the new tasks wait for approval.
  `coord say` (and a message box on the live page) routes one message to an answer, a running task or more work.
- `coord stats` and `.coordinator/metrics.jsonl` keep every run's time, cost, stages and gates after `terminate`.
  The live page and status lines show cost first.
- `coord selftest` starts and resumes one tiny agent the way runs do; `coord start` runs it once per Claude Code
  version, and `coord update` after updating, so a CLI change can't silently break every agent again.
- Every `gh pr` call targets the `origin` remote's repository, so repos with an `upstream` remote work.
- Plans: the planner fills `check`, splits by file or area instead of by step, and is asked once to justify a long
  chain; the plan card shows the plan's shape and other open runs that touch the same files.
- Models: officer and writer on Sonnet at low cost, reviewer effort now applied. The planner stays on Opus at high
  effort: a run is now only for bigger work, and its plan is the design.
- The reviewer opens every module the diff newly imports and checks where it may run; planners say in each brief
  which runtime a new module is for.
- Windows: prompts and role text go through stdin and files, not the command line; an npm `claude.cmd` is started
  through its node script; toast notifications; `tasks.json` reads retry while a writer replaces it.
- Screenshots: builders of UI tasks can shoot their own worktree, in the browsers `shots.browsers` lists, and the
  reviewer checks them.

## 0.10.3 - 2026-10-29

- The pull request description is one short paragraph, one to three lines, on what the change does and why. The
  `## Changes` list is gone too.

## 0.10.2 - 2026-10-29

- The pull request description is a short paragraph on what the change does and why, then `## Changes`. Nothing
  else: no Decisions, Testing or Notes sections, and no list of related changes in other repositories.

## 0.10.1 - 2026-10-29

- The pull request no longer ends with a "Left to do" section. Manual steps and files changed outside the repo stay
  on the live page and in `coord todo` and `coord status`.

## 0.10.0 - 2026-10-29

- Coordinator runs on Windows. `install.ps1` (or `install.sh` from Git Bash) links `/coordinate` to the clone with a
  junction, puts `coord` and `coord.cmd` in `~\.local\bin` and adds that folder to your user PATH, so `git pull`
  and `coord update` keep it current.
- On Windows, `coord` locks the task store with `msvcrt`, checks and stops agents with Windows process calls, starts
  them in their own hidden process group and runs the project's `setup`, `gate` and `dev` commands in Git Bash, so
  one config works on every OS. It always reads and writes UTF-8.
- Agents on Windows use the Bash tool (Git Bash) only, so the deny rules and the hook cover every shell command.
  Their write checks ignore the case of paths, like Windows does.
- Agents' settings allow `Bash(coord:*)`, so auto mode never stops a background agent to ask before it runs
  `coord`. Owner-only commands are still refused.
- Line endings stay LF in every checkout (`.gitattributes`), so the shell scripts run in Git Bash.

## 0.9.0 - 2026-10-29

- The pull request reads like a senior engineer wrote it. Once every task has merged, a new writer agent (Sonnet)
  reads the plan, each task's notes and the diff, and writes the description: what the change does and why, the
  changes by area, the decisions a reviewer might question, how to test it, and real risks. No task ids, tokens,
  times or process.
- While the run works, the description is the plan's goal and a checklist of what has merged. The quoted request,
  the token table and the full plan are gone. Steps left for you stay, under "Left to do".
- If the writer can't finish, its task is skipped and the short description stays; the run still finishes.

## 0.8.0 - 2026-10-29

- Every agent works like a senior engineer: it understands the code before changing or judging it, follows the
  project's patterns, makes its own calls, owns the result and writes tight.
- Agents write code that needs no comments. A comment appears only where a senior engineer would add one, as a
  short line on a non-obvious why; no narration, restated code, banners, TODOs or commented-out code. The reviewer
  flags anything more. A project's own comment rules still win.

## 0.7.0 - 2026-10-29

- A Files tab on the live page lists every file in the run's folder and in each task's folder, hidden files included
  and with no limit, with images as thumbnails. A task's files tab shows the same.
- A click opens the file in the viewer. Video, audio, PDFs and HTML pages open in their own browser tab (video can
  seek; an agent's page runs sandboxed, away from the live page's controls). Every file also has buttons to open it
  in a new tab or show it in Finder, and so does the viewer, so a file it can't preview is never a dead end.
- Notes, officer reports and the plan link the files they name: a screenshot named in a review opens from the task's
  folder. Markdown images (`![](shot.png)`) show inline, and Markdown links to local files open in the viewer.
- The viewer also opens AVIF, BMP and ICO images.

## 0.6.0 - 2026-10-28

- Full auto, off by default: start a request with `<full auto>` and you count as away. The `/coordinate` session
  decides everything that would wait on you: it approves the plan, answers questions, settles officer stalemates and
  retries stalled tasks. When the run is done, it merges every pull request and ends every run. The planner,
  builders, reviewers and officer work exactly as before. Anything it can't settle waits for you, and then nothing
  is merged.
- A Full auto switch in the live page's top bar, and `coord auto on|off`, turn it on or off mid-run for a run and
  its follow-up runs. Follow-up runs started by a full-auto run are in full auto too.
- `coord wait --new` doesn't return for what already waits on you. `/coordinate` arms it after asking you, so it
  takes over when you switch full auto on, and sees approvals made on the live page.
- `coord -C <repo>` runs a command for another repo's run without `cd`, so follow-up runs need no permission
  prompt.
- The pull request lists the manual steps and outside files left for you, which stay there after the run's files
  are deleted.
- A merge right after a run finishes no longer makes the scheduler open a second pull request for the same branch.

## 0.5.1 - 2026-10-28

- Each task's branch is deleted once it is merged into the run branch, so only the pull request's branch remains.
- `coord terminate` deletes the run's task files in `.coordinator/`, read-only files included. A run that saved
  unfinished work as `wip.patch` keeps them.
- `/coordinate` runs `coord` without a permission prompt.

## 0.5.0 - 2026-10-28

- New brand: logo, banner and a redesigned live page with smooth, calm motion and light and dark themes.
- The live page shows each agent's conversation as it works, and opens any file or image in a viewer.
- The plan card shows the plan's short version, with an answer per question; approve or send changes from the page.
- The draft pull request opens when work starts, with a status body that is updated as tasks change.
- Asks that belong to another repo become follow-up runs, started there when the plan is approved.
- Everything waiting on you is in one list, on the live page and in chat. Agents record manual steps; `coord todo`
  lists them.
- Commits to `main` trigger the website's deploy (`.github/workflows/website.yml`).
- Screenshots are saved in the shots task's folder, and no artifact leaves the machine.
- The planner gives each agent the path of every file it needs.

## 0.4.2 - 2026-10-28

- `.coordinator/` reaches `.gitignore` through the run: one commit on the run branch, merged with its pull request.
  Coordinator no longer leaves an uncommitted `.gitignore` edit in your checkout, which diverged `main` from GitHub
  when it was committed after the pull request was merged.

## 0.4.1 - 2026-10-28

- The clone install is the main one: it lists the command as plain `/coordinate`, which plugins can't.
- `/coordinate update` (`coord update`) pulls the latest version of a clone install.

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
