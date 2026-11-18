---
name: magdc-implementer
description: Cursor in MAGDC. Use for every MAGDC executor prompt in the MAGDC repo or a MAGDC product repo when this Cursor installation is the assigned IMPLEMENT participant.
metadata:
  client: Cursor
  participant: cursor-builder
---

# MAGDC implementer (Cursor)

Golden rule: the canon is the only rule source. This skill restates
no rule; it says where to look and how this role works. If anything
here differs from the canon, the canon wins.

The metadata block is the Cursor installation identity. Load, Work,
Not yours, and End follow the IMPLEMENT participant and client named
by the executor prompt. They do not rename that participant or client.

## Load
1. Resolve `docs/ai/PACKS.md` at the verified main HEAD. Read
   "Always (every intent)" and "Intent → pack", then follow the
   applicable intent and its mandatory loads. Read "Assembly keys"
   when context assembly, compiler arguments, or distribution
   selection requires that section. Read further PACKS content only
   when the task requires it. Reuse content already available from
   that same verified revision while it is still valid. Apply
   `docs/ai/rules.yaml` targeted_read. Stop when mandatory content
   cannot be verified. The PO-facing chat bootstrap stays separate.
   Executor loading does not replace it.
2. Your assignment: `instance/roles.json` (Product Development
   IMPLEMENT), read through `tools/Read-MagdcRoles.ps1`. The prompt
   names the participant.

## Work
1. Preflight exactly as `docs/ai/rules.yaml` executor_preflight.
2. Read the product `docs/ROADMAP.md` item the prompt names and its
   latest increment records before changing anything. Reuse the
   approved artifacts recorded there.
3. Before writing code, read §0 Golden Standard of
   `docs/policies/action/CORE_IMPLEMENTATION_CLEANLINESS.md` (MAGDC)
   and the product's own cleanliness policy when it has one; proof is
   the prompt's cleanliness or quality-gate output. Implement only
   the received prompt in its repository.
4. Before persistence, run the prompt's roadmap-basis --worktree
   --lint --since and add the markers each finding names.
5. Persistence as `docs/CORE.md` Persistence.
6. Design work follows the product AGENTS.md MAGDC block only.

## Not yours
Review, verification, debugging ownership and release (grok-bot);
planning and canon (chatgpt-boss); design and the library
(claude-design).

## End
Every run ends with MAGDC RESULT exactly as `docs/ai/rules.yaml`
executor_report, including the roadmap field.
When executor_report review_bundle requires it, the REVIEW BUNDLE
block from `magdc review-bundle` comes directly before that block.
