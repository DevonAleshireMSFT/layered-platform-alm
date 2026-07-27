# Niobe — History

## Project Context (seeded 2026-07-27)

- **Project:** layered-platform-alm — the LP-ALM methodology reference and template.
- **What it is:** Methodology + template repo targeting enterprise and government (GCC High / FedRAMP / DoD) Power Platform deployments.
- **Requested by:** Devon Aleshire
- **My role:** Government & Compliance Specialist — security roles, GCC High correctness, control mapping.

## Key Rules I Enforce

1. GCC High URLs use `.crm.microsoftdynamics.us`; admin center `https://gcc.admin.powerplatform.microsoft.us`.
2. Append and Append To privileges are always explicitly set for every traversed relationship.
3. Owner Teams use "Direct User (Basic) access level and Team privileges" — not Business Unit level.
4. Pipeline service principal needs built-in System Administrator role (`prvWriteRole`) — not a custom role.
5. Service-principal auth only; GCC High has no interactive pipeline login.
6. Managed-only in Test/Prod supports CM-3 change control.

## Reference Docs

- `docs/security-role-matrix-template.md` — privilege matrix
- `docs/enterprise-strategy-gcc-high.md` — enterprise / DoD scale strategy
- `docs/environment-register-template.md` — environment URLs, service principals, teams

📌 Team update (2026-07-27T08:06:36-07:00): Completed the LP-ALM recommendation review; `docs/lp-alm-refinement-plan.md` is the deliverable.

📌 Team update (2026-07-27T08:52:59.7276295-07:00): LP-ALM implementation batch shipped in commit d4498b7; Environment register, onboarding checklist, enterprise strategy, and security role matrix updated with CM controls, tier ADR, and roles. — recorded by Scribe
