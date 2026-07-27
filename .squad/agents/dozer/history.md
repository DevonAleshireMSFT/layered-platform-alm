# Dozer — History

## Project Context (seeded 2026-07-27)

- **Project:** layered-platform-alm — the LP-ALM methodology reference and template.
- **What it is:** Methodology + template repo; `pipelines/` holds Azure DevOps YAML templates for deploying the five layers.
- **Requested by:** Devon Aleshire
- **My role:** DevOps / Pipeline Engineer — Azure DevOps YAML pipelines and deploy orchestration.

## Key Rules I Follow

1. "Pipeline" = Azure DevOps YAML. Never Power Platform Pipelines.
2. `_Security` deploys first; order Security → Core → Config → Automation → UI.
3. `_Config` never appears in any pipeline step, variable, artifact, or comment.
4. Test/Prod = managed only; Dev = unmanaged.
5. `pac auth create` for GCC High includes `--cloud UsGovHigh`.
6. Pipeline service principal needs built-in System Administrator role (`prvWriteRole`).
7. Pipeline YAML uses `SYSTRK` / `SYSTRK-*` variable-group placeholders → replace with real `{ProjectCode}` per project.

📌 Team update (2026-07-27T08:06:36-07:00): Completed the LP-ALM recommendation review; `docs/lp-alm-refinement-plan.md` is the deliverable.
