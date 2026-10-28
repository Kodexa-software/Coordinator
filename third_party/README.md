# Third-party material

Coordinator bundles parts of two other projects, so that it can work their way without depending on them being
installed. Each folder keeps its original licence. The rest of Coordinator is MIT.

## impeccable/

- **From:** [Impeccable](https://github.com/pbakaus/impeccable) by Paul Bakaus, skill version 4.8.0
- **Licence:** Apache License 2.0 ([LICENSE](impeccable/LICENSE)); the upstream notice is in
  [NOTICE.upstream.md](impeccable/NOTICE.upstream.md). Its only entry concerns `ios.md` and `android.md`, which are
  not bundled here.
- **Copied, unchanged:** 19 files from `skill/reference/` (UI craft: the quality floor, surface modes, shaping,
  type, colour, layout, motion, polish, simplifying, toning down, UX copy, hardening, responsive, onboarding,
  performance, and the technical audit).
- **Not bundled:** the launcher and its binary, detectors, hooks, live mode, browser tooling, helper agents,
  `new-work.md`, `critique.md` and `component-review.md`, which are built around them, and the platform files.
- **Adapted:** [roles/design.md](../roles/design.md) quotes Impeccable's core principles, "How to design" and
  surface modes from its `SKILL.md` unchanged, and adds Coordinator's own instructions on when to read which
  bundled reference and which steps to skip. That file is a modified excerpt of Apache-2.0 material.

## icm-architect/

- **From:** [icm-architect](https://github.com/RinDig/icm-architect) by Jake Van Clief, implementing Interpretable
  Context Methodology (Van Clief & McDermott, arXiv:2603.16021)
- **Licence:** MIT ([LICENSE](icm-architect/LICENSE))
- **Copied, unchanged:** `SKILL.md`, `references/core.md`, `references/forms.md`, `references/system-map.md`,
  `scripts/index.py` and `scripts/links.py`.
- **Used by:** [roles/mapper.md](../roles/mapper.md), which builds a project's map in `.coordinator/map/` with the
  System map method. Coordinator's `.coordinator/` folder follows ICM's invariants: a small generated entry file,
  one folder per job, status on disk.
