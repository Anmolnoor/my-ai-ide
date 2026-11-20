---
name: api-design
description: Use when adding, changing, or reviewing HTTP/REST/GraphQL endpoints. Enforces a checklist for naming, versioning, errors, pagination, auth, and backward compatibility before the endpoint is implemented.
---

# API design checklist

Before writing the handler, answer each item in writing:

- **Resource & verb** — Noun-based URL, correct method (GET idempotent, POST creates, PUT replaces, PATCH partial, DELETE). For GraphQL: query vs mutation correctness.
- **Versioning** — How will v2 ship without breaking v1? URL prefix, header, or additive-only schema.
- **Request shape** — Required vs optional fields, types, validation rules. Document them.
- **Response shape** — Success envelope consistent with the rest of the API. Include timestamps/IDs clients will need.
- **Error shape** — Same structure across all endpoints (code, message, details). Map to correct HTTP status.
- **Pagination** — Cursor or offset. Max page size. Default page size.
- **Idempotency** — For POST/PATCH, can a retry duplicate work? If yes, add idempotency key or make it safe.
- **Auth** — Who can call it? What scope/role? Enforced where?
- **Backward compat** — Does this break existing clients? If yes, flag it and propose a migration.

Blockers:
- Do not implement the endpoint until every item above has an explicit answer.
