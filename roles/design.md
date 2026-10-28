# Design languages for UI tasks

<!-- Parts of this file quote Impeccable (https://github.com/pbakaus/impeccable, Apache License 2.0); see
third_party/README.md. The quoted passages are unchanged; the rest is Coordinator's. -->

A run's UI tasks follow exactly one design language, recorded in `tasks.json` as `design`:

- **project:** the project's own design guides and its established UI. The paths are in `design.source`.
- **impeccable:** Impeccable's design philosophy, bundled with Coordinator in `third_party/impeccable/`.
- **other:** whatever the owner named or linked, quoted in `design.source`.

Whatever the choice, the project's own hard rules (accessibility, file layout, frameworks, the owner's
standing rules) still apply, and design ambition never adds features or scope.

## Impeccable

### Core, quoted from Impeccable's SKILL.md

> - Finish the job. No hedging, no shortcuts: the deliverable is complete, except assets the user must provide.
> - Scale ambition to the surface's mode (see Modes). Persuade and Experience get full commitment: bold,
>   distinct work with a point of view. On Operate and Read, ambition shows as precision and restraint, and
>   patterns the visitor already knows earn their place.
> - Verify by looking at the rendered result at the sizes it ships at, and batch the checks: fix what one look
>   shows before looking again, rather than screenshotting after every tweak.

> - **The brief wins.** Honor pinned aesthetics, eras, materials, fonts, and palettes even when they conflict
>   with a saturated-pattern warning. Redirecting a clear brief toward your taste is failure.
> - **Refinement preserves; redesign replaces.** Refinement keeps the incumbent identity, behavior, copy, and
>   everything outside scope. Ask before replacing factual copy or adding claims. Redesign keeps product truth,
>   content, function, native affordances, and constraints, but treats the old look as evidence and
>   anti-reference; choose a replacement world in new-work and replace DESIGN.md. Never split the difference
>   into polish on the discarded look.
> - **Visual authority is evidence, not a filename.** Missing DESIGN.md alone does not make a project
>   greenfield; new-work decides whether to preserve, expand, or replace the incumbent world.

> The mode names what the visitor's success looks like on this surface.
>
> - **Persuade:** the visitor decides and acts; design is the product. Landing pages, marketing, campaigns,
>   pricing. Earn attention and action. Ship real imagery when the brief needs it; follow the committed world,
>   not category habit.
> - **Operate:** the visitor completes a task. App UI, dashboards, editors, admin, settings, tools.
>   Scanability, consistency, native expectations, and the real usage scene outrank expression. Brand lives in
>   precise details.
> - **Read:** the visitor understands something. Docs, articles, guides, help, changelogs. Structure for
>   comprehension, then make the reading experience worth staying in.
> - **Experience:** the visitor is inside the work itself. Portfolios, galleries, showcases. Let the artifact
>   lead from the first viewport; the interface recedes.

### Which bundled reference to read

All are in `third_party/impeccable/reference/` under Coordinator's folder. Read only the ones the task needs.

| When | Read |
|---|---|
| Before any UI edit, always | `craft-floor.md` |
| To place the surface | `mode-operate.md`, `mode-read.md` or `mode-persuade.md`; `operate.md` for Operate and Read |
| New or reshaped UI, before code | `shape.md`, then `typeset.md`, `colorize.md` and `layout.md` as the work needs |
| Refining existing UI | `polish.md`; `distill.md` to simplify, `quieter.md` to tone down, `clarify.md` for UX copy |
| Making it production-ready | `harden.md` (errors, i18n, edge cases), `adapt.md` (responsive), `onboard.md` (empty states, first run), `optimize.md` (performance), `animate.md` (motion) |
| Reviewing a UI change | `audit.md` (accessibility, performance, responsive, anti-patterns) |

### Differences from Impeccable itself

- Coordinator doesn't ship Impeccable's launcher, detectors, hooks, live mode or helper agents. Skip any step that
  runs `impeccable ...` commands or needs them. Where a step loads `PRODUCT.md` or `DESIGN.md` through the
  launcher, read those files directly if they exist.
- A reference that points to a file not bundled here (for example `new-work.md` or `critique.md`): use the
  bundled references above instead.
- "Redesign" and bolder escalation only when the owner's words ask for them. By default UI work is refinement,
  and refinement preserves the incumbent identity.
