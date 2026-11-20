---
name: tdd
description: Use when the user asks to add a feature, fix a bug, or explicitly requests TDD. Enforces red-green-refactor as a hard gate; no implementation code may be written before a failing test exists and has been run.
---

# TDD — red, green, refactor

Hard sequence. Do not skip steps.

1. **Red** — Write a single test that encodes the desired behavior or reproduces the bug. Run it. Confirm it fails for the right reason (not a typo or missing import). If it passes or errors for the wrong reason, fix the test first.
2. **Green** — Write the minimum code to make the test pass. No extra features, no "while I'm here" cleanup. Run the test. Confirm it passes.
3. **Refactor** — Only now may you improve structure. Run tests after each refactor; revert anything that breaks them.

Blockers:
- Do not write implementation before step 1 is verified red.
- Do not refactor before step 2 is verified green.
- If the user says "just make it work, skip tests," ask once whether to fall back. Do not silently drop TDD.
