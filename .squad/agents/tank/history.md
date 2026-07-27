# Tank — History

## Project Context (seeded 2026-07-27)

- **Project:** layered-platform-alm — the LP-ALM methodology reference and template.
- **What it is:** Methodology + template repo for layered Dataverse solutions in enterprise and government (GCC High / FedRAMP / DoD) environments.
- **Requested by:** Devon Aleshire
- **My role:** Power Platform / Dataverse Engineer — schema, solutions, PAC CLI, connection references.

## Key Rules I Follow

1. Schema lives only in `_Core`; never in `_UI`.
2. `_Config` (env-var values) is never committed.
3. Connection references use service accounts, not personal credentials.
4. PAC auth to GCC High uses `--cloud UsGovHigh`.
5. Naming: `{prefix}_table`, `{prefix}_{entity}name`, `{prefix}_{entity}id`; solutions `{ProjectCode}_{Layer}`.

## Environment Inventory

- Dev: unmanaged sandbox, `https://{org}-dev.crm.microsoftdynamics.us`
- Test: managed, `https://{org}-test.crm.microsoftdynamics.us`
- Prod: managed, `https://{org}.crm.microsoftdynamics.us`
- All GCC High URLs use `.crm.microsoftdynamics.us`.

📌 Team update (2026-07-27T08:06:36-07:00): Completed the LP-ALM recommendation review; `docs/lp-alm-refinement-plan.md` is the deliverable.
