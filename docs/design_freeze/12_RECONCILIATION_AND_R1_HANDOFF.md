# ATLAS FRONT — Reconciliation and R1 Handoff

Status: **required handoff step before R1 code changes**

This document exists because the current remote `main` baseline does not contain the unpublished local Singleplayer commits that were completed before the visual redesign was frozen.

Known local commits that must be preserved:

- `89a9a91` — Offline-Singleplayer-Flow and UI
- `3641fe6` — Multi-AI, cards/combat/event log + 100-match QA harness
- `b04085e` — Singleplayer polish, captures, release preset

The design-freeze documentation lives on `origin/docs/design-freeze-v1` and must be brought into the same working history before R1 begins.

## Required local repository procedure

Run this only in the real working checkout that contains the unpublished Singleplayer commits.

1. Verify repository and working tree:

   ```bash
   git status
   git rev-parse --show-toplevel
   git log --oneline --decorate -8
   ```

   Expected checkout root is the existing ATLAS FRONT repository. The working tree should be clean before history reconciliation.

2. Verify the unpublished Singleplayer head is present:

   ```bash
   git show --stat --oneline b04085e
   git merge-base --is-ancestor 89a9a91 b04085e
   git merge-base --is-ancestor 3641fe6 b04085e
   ```

   If any known commit is missing, stop and report instead of recreating or resetting history.

3. Fetch the remote documentation branch:

   ```bash
   git fetch origin
   git branch -r --list origin/docs/design-freeze-v1
   ```

4. Create the redesign implementation branch from the current local Singleplayer head:

   ```bash
   git switch -c redesign/v1 b04085e
   ```

   If `redesign/v1` already exists, inspect it first. Do not force-reset it.

5. Merge the frozen design documentation into the implementation branch:

   ```bash
   git merge --no-ff origin/docs/design-freeze-v1
   ```

   Conflict policy:

   - preserve all unpublished Singleplayer implementation commits;
   - preserve all `docs/design_freeze/**` files from the documentation branch;
   - do not resolve a conflict by dropping domain/network/save/AI work;
   - do not rewrite gameplay behavior while resolving documentation/history conflicts;
   - if a real semantic conflict appears, stop and report it.

6. Verify the combined history:

   ```bash
   git status
   git log --oneline --decorate --graph -20
   git merge-base --is-ancestor b04085e HEAD
   git merge-base --is-ancestor origin/docs/design-freeze-v1 HEAD
   ```

   Both ancestry checks must succeed.

7. Inventory the local Singleplayer delta against remote `main`:

   ```bash
   git diff --name-status 3e3cd92..b04085e
   git show --name-status --oneline 89a9a91
   git show --name-status --oneline 3641fe6
   git show --name-status --oneline b04085e
   ```

   Append any newer SP/AI/save/persistence/presentation files that are absent from `11_R0_IMPLEMENTATION_INVENTORY.md` to the local copy of that inventory. This is documentation-only reconciliation; do not redesign those files yet.

8. Run the existing test baseline available in the local checkout.

   Minimum expectations from the known pre-redesign baseline:

   - full domain/presentation regression suite remains green;
   - 100-match AI-vs-AI QA still completes without illegal commands, safety hits, softlocks or crashes;
   - current Windows/export smoke remains runnable if its harness is available;
   - no test should be weakened or deleted merely to complete reconciliation.

   Discover and use the actual test commands/scripts in the local checkout rather than inventing filenames that may differ from remote `main`.

9. Produce a reconciliation report before R1:

   ```text
   Branch: redesign/v1
   HEAD: <sha>
   Contains b04085e: PASS/FAIL
   Contains design-freeze branch: PASS/FAIL
   Working tree clean: PASS/FAIL
   Tests run: ...
   Test result: ...
   Newer local files added to R0 inventory: ...
   Conflicts encountered: ...
   R1 ready: YES/NO
   ```

## Hard prohibitions during reconciliation

Do not:

- push or rewrite `main`;
- rebase/drop/squash the unpublished Singleplayer commits merely for tidiness;
- delete the old asset pack;
- redesign screens;
- change rules, topology, RNG, card behavior or network protocol;
- replace the save system with the older remote implementation;
- start R1 until the merged branch is verified and tests are green.

## R1 handoff condition

R1 may begin only when one branch contains both:

1. the latest local Singleplayer implementation through `b04085e`; and
2. the complete frozen redesign documentation through the current `docs/design-freeze-v1` head.

Once that condition is met, `docs/design_freeze/10_IMPLEMENTATION_ROADMAP.md` and `11_R0_IMPLEMENTATION_INVENTORY.md` govern the implementation sequence.

## First R1 scope after reconciliation

The first code-changing milestone remains deliberately narrow:

- rebuild the centralized runtime theme/tokens;
- add Inter-based typography/fallback wiring;
- implement frozen neutral/player/semantic color roles;
- implement reusable Primary/Secondary/Destructive button families;
- implement focus/hover/pressed/disabled/busy states;
- implement panel/modal/tooltip/toast base styles;
- support UI-scale presets 90/100/110/125;
- add a representative component-gallery/fixture if practical.

R1 must **not** yet redesign the world map, dice, cards, AI flow, multiplayer screens, domain rules or network behavior.
