---
name: rfc
description: Use when the user asks to design a feature, wants a design doc or RFC, or proposes a non-trivial architectural change. Produces a structured document before any code is written.
---

# RFC / Design doc

Produce a single markdown doc before writing code. Keep it under one page. Structure:

1. **Context & problem** — What exists today, what's broken or missing, who is affected.
2. **Goals / non-goals** — What this change will and will not do. Non-goals prevent scope creep.
3. **Options considered** — At least two. For each: one paragraph of what it looks like.
4. **Tradeoffs** — Table or bullets: cost, risk, complexity, reversibility per option.
5. **Recommendation** — Pick one. State why.
6. **Open questions** — Things you cannot decide without more input.

Blockers:
- Do not start implementation until the user has read and approved the doc.
- If you catch yourself writing code to "see if it works," stop and finish the doc first.
