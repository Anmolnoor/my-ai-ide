---
name: debugging
description: Use when the user reports a bug, regression, crash, or unexpected behavior. Enforces reproduce, hypothesize, bisect, fix root cause, regression test. Blocks "try random changes until it works."
---

# Debugging workflow

Hard sequence. Do not skip.

1. **Reproduce deterministically.** Get a command, input, or test that triggers the bug every time. If you cannot reproduce, stop and ask for repro steps — do not guess-fix.
2. **Hypothesize in one sentence.** State what you think is wrong before touching code. If you have no hypothesis, read more code; do not edit.
3. **Bisect.** Narrow the cause: git bisect for regressions; binary-search the input for data-dependent bugs; comment out code paths to isolate. Identify the single line or commit responsible.
4. **Fix root cause, not symptom.** If the fix is "add a null check," ask why null arrived. Patch the source, not the downstream.
5. **Regression test.** Add a test that fails before the fix and passes after. Commit the test with the fix.

Blockers:
- Do not change code before step 1 is verified.
- Do not commit a fix without step 5.
