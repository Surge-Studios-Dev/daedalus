# Parallel build — fanning M3 out across agents

Ladle was built one screen group per session, serially. That was right for
the first app (every session recalibrated the conventions), but Daedalus
removes the reason: the conventions are stamped (CLAUDE.md), the merge bar
is enforced by a hook, and after M2 the core logic is test-locked. From
there, feature tabs are independent by construction — they share
`lib/modules/`, `lib/core/`, and surge_ui, and own their `lib/features/<id>/`
directory. M3 is the milestone to parallelize.

## Preconditions (all hard)

1. **M0 and M2 are done**: the moat gate passed and `lib/core/` +
   `lib/models/` are test-locked. Parallel agents consume core logic; they
   never edit it.
2. **Spec §6 is approved** for every screen in the fan-out. Agents build to
   spec; ambiguity resolution is serial (ask the human), so spend it before
   forking.
3. The screen board baseline is captured, so each agent can diff its own
   visual impact.

## The fan-out

One agent per screen group (a feature tab, or a coherent slice of one),
each in its own git worktree:

```
git worktree add ../<slug>-wt-<tab> -b feat/<tab>
```

Each agent's prompt is the same shape:

> Work in this worktree only. Read CLAUDE.md, `.daedalus/state.yaml`,
> `design/spec.md` §6 for `<TAB-IDs>` and §8 for this tab. Reshape
> `lib/features/<tab>/` into those screens. Rules of engagement: do NOT
> touch `lib/modules/`, `lib/core/`, `lib/models/`, `lib/dev/fixtures.dart`,
> or another feature's directory — if you need a change there, STOP and
> report it instead. New shared-component needs go on a list, not into
> surge_ui. Each screen's §8 cases become tests before it is done. Commit
> per screen with the spec ID.

The don't-touch list is what makes merges trivial: modules/core/models are
frozen inputs, features are disjoint outputs. Cross-cutting needs (a new
core function, a fixtures change, a shared component) are the integrator's
queue, not any parallel agent's job.

## The integrator (one serial session at the end)

1. Merge the branches (they should not conflict; a conflict means the
   rules of engagement were broken — read that diff hard).
2. Work the cross-cutting queue the agents reported (core additions,
   fixtures growth, shared-component promotions).
3. Full suite + `flutter analyze` on the merged tree (the merge bar hook
   only proved each branch separately).
4. Re-capture the screen board, eyeball every tab in both modes against
   the design reference, and update `.daedalus/state.yaml`.

## Sizing

Two to four parallel agents is the sweet spot: below that the integrator
overhead isn't paid back; above it the cross-cutting queue and review
surface grow faster than the wall-clock savings. A 4-tab app is one
integrator plus one agent per tab.
