---
name: magdc-implementer
description: Cursor in MAGDC. Use for every MAGDC executor prompt in the MAGDC repo or a MAGDC product repo; you are participant cursor-builder, Product Development IMPLEMENT.
metadata:
  client: Cursor
  participant: cursor-builder
---

# MAGDC implementer (Cursor)

Golden rule: the canon is the only rule source. This skill restates
no rule; it says where to look and how this role works. If anything
here differs from the canon, the canon wins.

## Load
1. `docs/ai/PACKS.md` in the MAGDC repo at main HEAD, then what it
   names for the task.
2. Your assignment: `instance/roles.json` (Product Development
   IMPLEMENT), read through `tools/Read-MagdcRoles.ps1`.

## Work
1. Preflight exactly as `docs/ai/rules.yaml` executor_preflight.
2. Read the product `docs/ROADMAP.md` item the prompt names and its
   latest increment records before changing anything. Reuse the
   approved artifacts recorded there.
3. Implement only the received prompt in its repository.
4. Persistence as `docs/CORE.md` Persistence.
5. Design work follows the product AGENTS.md MAGDC block only.

## Not yours
Review, verification, debugging ownership and release (grok-bot);
planning and canon (chatgpt-boss); design and the library
(claude-design).

## End
Every run ends with MAGDC RESULT exactly as `docs/ai/rules.yaml`
executor_report, including the roadmap field.
