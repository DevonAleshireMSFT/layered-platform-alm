# Squad Decisions

## Active Decisions

## Governance

- All meaningful changes require team consensus
- Document architectural decisions here
- Keep history focused on work, decisions focused on direction

## 2026-07-27

### 2026-07-27: Coordinator alias — "Neo"

**By:** Devon Aleshire (via Copilot CLI)
**What:** Devon addresses the Squad coordinator as **Neo**. Use "Neo" as the coordinator's name in greetings and conversation. The cast universe for this squad is The Matrix, so Neo fits the coordinator role.
**Why:** User preference stated during team setup — "For the coordinator, I will call you Neo."

### 2026-07-27: LP-ALM refinement plan verdict

**By:** Neo, informed by Morpheus, Tank, Niobe, Dozer, Link, and Fact Checker
**What:** Evolve LP-ALM from a fixed five-layer prescription into a methodology centered on non-negotiable invariants with optional governed layers. `_Config` becomes an optional governed pattern rather than a mandatory source-controlled or pipeline layer. The deliverable refinement plan is `docs/lp-alm-refinement-plan.md`.
**Why:** Architecture, Dataverse mechanics, GCC High governance, pipeline feasibility, synthesis, and devil's-advocate reviews converged on preserving core ALM/security invariants while allowing project-specific layer choices and explicit mitigations.

### 2026-07-27: UI solution naming — avoid "User"

**By:** Devon Aleshire (via Copilot CLI)
**What:** Do NOT name the user-facing UI solution `_UI_User` (the word "User" causes a previously-noted issue — likely collision/confusion with the Dataverse `systemuser` / "User" concept). Use **`{ProjectCode}_UI_Operations`** for the operational/user-facing UI solution instead. Keep `{ProjectCode}_UI_Admin` for the admin UI. Naming pattern for the UI split is therefore `_UI_Operations` + `_UI_Admin`.
**Why:** User directive during LP-ALM refinement — "Do not use UI_User ... per the previous noted issue with User." Applies framework-wide and in all LP-ALM docs, templates, and pipelines going forward.

