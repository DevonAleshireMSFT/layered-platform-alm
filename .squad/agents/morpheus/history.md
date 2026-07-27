# Morpheus — History

## Project Context (seeded 2026-07-27)

- **Project:** layered-platform-alm — the Layered Platform ALM (LP-ALM) methodology reference and template.
- **What it is:** A methodology + template repo (NOT a live Power Platform project) for building layered Dataverse solutions targeting enterprise and government (GCC High / FedRAMP / DoD) environments. Contains `LP-ALM.md` (full methodology), `pipelines/` (Azure DevOps YAML templates), `.ai/` (AI grounding), and `docs/` (templates).
- **Requested by:** Devon Aleshire
- **My role:** Lead / Solution Architect — I own the five-layer model and its boundary rules.

## Key Rules I Enforce

1. `_Config` is never committed to source control and never in a pipeline.
2. `_Security` deploys first in every environment.
3. `_UI` cannot contain schema — schema lives in `_Core`.
4. Test/Prod receive managed solutions only; Dev receives unmanaged.
5. Deploy order: Security → Core → Config → Automation → UI.

## Notes

- Framework is still evolving — expect methodology changes; keep `.ai/` context files in sync with `LP-ALM.md`.
- Coordinator goes by **Neo** (per Devon's preference).

📌 Team update (2026-07-27T08:06:36-07:00): Completed the LP-ALM recommendation review; `docs/lp-alm-refinement-plan.md` is the deliverable.

📌 Team update (2026-07-27T08:52:59.7276295-07:00): LP-ALM implementation batch shipped in commit d4498b7; .ai/context.md and .ai/layers.md aligned to the refined LP-ALM model. — recorded by Scribe
