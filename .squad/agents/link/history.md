# Link — History

## Project Context (seeded 2026-07-27)

- **Project:** layered-platform-alm — the LP-ALM methodology reference and template.
- **What it is:** Methodology + template repo. It is documentation-first: `LP-ALM.md` is the full methodology; `.ai/` grounds AI assistants; `docs/` holds reusable templates.
- **Requested by:** Devon Aleshire
- **My role:** Methodology Writer / Documentation — keep the methodology and its context files coherent and in sync.
- **Public site:** https://devonaleshiremsft.github.io/layered-platform-alm/

## Key Rules I Preserve in Docs

1. `_Config` is never committed / never in a pipeline.
2. `_Security` deploys first.
3. `_UI` cannot contain schema.
4. Managed-only in Test/Prod; unmanaged in Dev.
5. GCC High uses `.crm.microsoftdynamics.us`.
6. Keep placeholders (`{ProjectCode}`, `{prefix}`, `{org}`) intact so the repo stays a template.

## Notes

- Framework is evolving — `LP-ALM.md` leads, `.ai/` and `docs/` follow. Watch for drift.
- After changes, provide a Conventional Commits message with a layer/area scope.

📌 Team update (2026-07-27T08:06:36-07:00): Completed the LP-ALM recommendation review; `docs/lp-alm-refinement-plan.md` is the deliverable.

📌 Team update (2026-07-27T08:52:59.7276295-07:00): LP-ALM implementation batch shipped in commit d4498b7; LP-ALM.md refined to invariant model, Config Gate, tiers, UI Operations/Admin, NIST/ATO; docs/lp-alm-refinement-plan.md finalized. — recorded by Scribe
