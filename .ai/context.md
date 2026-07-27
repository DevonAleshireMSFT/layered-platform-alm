# Project AI Context — LP-ALM Reference Implementation

> This file is the primary AI grounding document for this repository.
> Load this file first when using GitHub Copilot, Azure AI Foundry, or any AI assistant
> to work on this project. All suggestions should align with the conventions below.
> Full detail lives in `LP-ALM.md` and `docs/lp-alm-refinement-plan.md`.

---

## Project Identity

| Field | Value |
|---|---|
| **Project Code** | `{ProjectCode}` — replace with actual project code (e.g., `SYSTRK`) |
| **Publisher Display Name** | `{Project Name} Platform` |
| **Publisher Unique Name** | `{projectname}platform` |
| **Publisher Prefix** | `{prefix}` — 2–5 char lowercase (e.g., `sys`) |
| **Methodology** | Layered Platform ALM (LP-ALM) v1.0 |

---

## Environment Inventory

| Environment | Type | URL | Deployment Method |
|---|---|---|---|
| Dev | Unmanaged sandbox | `https://{org}-dev.crm.microsoftdynamics.us` | Manual / PAC CLI |
| Test | Managed | `https://{org}-test.crm.microsoftdynamics.us` | Azure DevOps pipeline |
| Prod | Managed | `https://{org}.crm.microsoftdynamics.us` | Azure DevOps pipeline |

**Cloud context example:** GCC High environments use `.crm.microsoftdynamics.us`
**Admin Center example:** `https://gcc.admin.powerplatform.microsoft.us`

---

## LP-ALM Model: Mandatory Invariants + Optional Layers

LP-ALM starts with ordered mandatory invariants and adds optional governed solution layers only when justified.

### Authoring Principles

LP-ALM is a secure framework, not an authority over every tenant, agency, impact level, or identity policy.

- Use **RECOMMENDED** and **SHOULD** for controls outside the framework's authority.
- Reserve **MUST**, **REQUIRED**, and equivalent language for true framework invariants: `_Security` deploys first, `_Core` owns schema, `_Config` and raw values are never committed, zero secrets are written to source, UI solutions are schema-free, and upper environments receive managed solutions.
- Treat GCC High, IL4, IL5, FedRAMP, and similar regulated environments as example contexts where secure-environment controls are often useful.
- For connection references, the recommended default is a dedicated service account. When unavailable, use a least-privilege delegated identity with documented ownership, credential rotation, approval authority, and environment-register evidence.

### Mandatory invariants

| Order | Layer / Gate | Purpose | Source Control | Pipeline |
|---|---|---|---|---|
| 1 | `{ProjectCode}_Security` | Security roles, field security profiles, protected access structures | ✅ Yes | ✅ Yes |
| 2 | `{ProjectCode}_Core` | All Dataverse schema and environment variable definitions | ✅ Yes | ✅ Yes |
| 3 | Config Gate | Deployment-controlled values and bindings; not a solution | ❌ Values never | ✅ Validation / injection only |

### Optional solution layers

| Layer | Create when... | Source Control | Pipeline |
|---|---|---|---|
| `{ProjectCode}_Integration` | Shared, numerous, separately owned, independently released, or government-governed integrations exist | ✅ Yes | ✅ Yes |
| `{ProjectCode}_Automation` | Flows, connectors, connection references, scheduled jobs, or automation runtime assets exist | ✅ Yes | ✅ Yes |
| `{ProjectCode}_UI_Operations` | User-facing operational apps, dashboards, site maps, custom pages, PCF, or UX web resources exist | ✅ Yes | ✅ Yes |
| `{ProjectCode}_UI_Admin` | Admin capability has distinct ownership, cadence, persona, deployment target, or blast radius | ✅ Yes | ✅ Yes |
| `{ProjectCode}_Reporting` | Reporting artifacts are substantial and have an independent lifecycle | ✅ Yes | ✅ Yes |
| `{ProjectCode}_TestData` | Synthetic test datasets or validation assets have an independent lifecycle | ✅ Yes | Optional |

---

## Architecture Tiers

| Tier | Solutions | Use when... |
|---|---|---|
| **Minimum** | Security + Core + UI (`{ProjectCode}_UI_Operations`) | No external integrations, no cross-boundary/CUI data movement, and no privileged admin UI |
| **Standard** | Minimum + Automation | Automation exists but integrations are not shared, cross-boundary, or independently governed |
| **Enterprise** | Standard + Integration + multiple UIs as warranted | CUI exchange, shared connection references, cross-system orchestration, separately governed integrations, external ATO dependencies, or admin separation exist |

Use ADR-style justification for tier selection. Minimum means fewer components, not weaker controls.

---

## Secure-Environment Floor — Applies in Every Tier

- `_Security` is always separate and deploys first in every environment.
- `_Core` is the only schema layer.
- UI layers are schema-free: no tables, columns, relationships, or structural data definitions.
- Test and Prod receive managed solutions only; Dev receives unmanaged.
- Environment-specific values, secrets, tenant identifiers, connection bindings, and raw configuration values are never committed.
- Values are deployment-controlled artifacts backed by approved secret storage and documented by a non-secret environment configuration register.
- Connection references SHOULD use dedicated service accounts in upper environments. If service accounts are unavailable, use a least-privilege delegated identity with documented ownership, credential rotation, approval authority, and environment-register evidence.
- Sovereign-cloud settings SHOULD match the target tenant. For example, GCC High URLs use `.crm.microsoftdynamics.us`, and PAC CLI auth uses `--cloud UsGovHigh`.

---

## Config Gate Default

Do **not** present `_Config` as a required layer.

- Environment variable **definitions** live in `{ProjectCode}_Core`.
- Environment variable **values** and connection bindings are deployment-controlled data supplied through approved secret-backed mechanisms.
- The environment configuration register stores metadata only: logical name, environment, owner, needed/optional status, secret classification, source variable name, and last-reviewed date.
- A dedicated unmanaged `{ProjectCode}_Config` solution is allowed only as a documented high-control / audit-anchor alternative. It is manually applied, never committed, never referenced by pipelines, and must not contain secrets.

---

## Layer Decision Model

1. Always create `_Security`.
2. Always create `_Core` for all schema and environment variable definitions.
3. Default to the Config Gate; do not mandate `_Config`.
4. Create `_Automation` only when automation exists.
5. Create `_UI_Operations` when user-facing operational artifacts exist.
6. Add `_UI_Admin` only for distinct ownership, release cadence, deployment target, persona boundary, or blast radius.
7. Create `_Integration` only when integrations are shared, numerous, separately owned, independently released, or government-governed as cross-boundary services.
8. Create `_Reporting` or `_TestData` only when artifacts are substantial and have an independent lifecycle.

---

## Critical Rules — Do Not Violate These

1. **Configuration values are never committed to source control.** `_Config` is optional, unmanaged, manually applied only for justified high-control needs, and still never committed or referenced by pipelines.

2. **UI layers cannot contain schema.** If a table, column, relationship, or structural definition appears in `{ProjectCode}_UI_Operations` or `{ProjectCode}_UI_Admin`, move it to `_Core`.

3. **`_Security` deploys first.** Always. In every environment. The pipeline enforces this with dependency gates.

4. **Connection references SHOULD use service accounts, not personal credentials.** The recommended default is a dedicated service account. If unavailable, use a least-privilege delegated identity with documented ownership, credential rotation, approval authority, and environment-register evidence.

5. **Upper environments (Test, Prod) receive managed solutions only.** Dev receives unmanaged. Do not deploy a managed solution to Dev.

6. **The pipeline service principal uses the System Administrator built-in role** (not a custom role) when deploying security roles. This reflects the Dataverse platform constraint for `prvWriteRole`.

---

## Key Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Security roles deploy first | Yes — structural control | Access control must precede schema creation; eliminates a window where tables exist without governance |
| Config Gate default | Yes | Zero-secrets-in-repo guarantee while avoiding empty mandatory `_Config` layers |
| Optional unmanaged `_Config` | Allowed only with justification | Supports high-control audit evidence without weakening the no-source/no-pipeline rule |
| Managed solutions in Test/Prod | Yes | Prevents ad-hoc customization bypass; supports CM-3 change control |
| Per-layer pipelines + orchestration | Yes | Enables independent layer hotfixes + coordinated full deploys |
| Service principal auth preferred for pipelines | Yes | Recommended for non-interactive, auditable deployments; sovereign or regulated environments such as GCC High commonly use non-interactive authentication patterns |
| Single publisher per project | Yes | Prevents namespace collisions; schema prefix is consistent |
| Web resource split | Physical dependency direction | Integrity/schema-adjacent files live in `_Core`; UX-only files live in UI; `_Core` never depends on UI |

---

## Source Control Layout

```
.ai/                                ← AI context (this directory)
.gitignore                          ← Power Platform exclusions including _Config
LP-ALM.md                           ← Full methodology document
README.md                           ← Project overview
docs/                               ← Security role matrix, environment register, onboarding, refinement plan
pipelines/                          ← Azure DevOps YAML files
solutions/
  {ProjectCode}_Security/src/       ← Mandatory Security layer
  {ProjectCode}_Core/src/           ← Mandatory Core/schema layer
  {ProjectCode}_Automation/src/     ← Optional automation layer
  {ProjectCode}_Integration/src/    ← Optional integration layer
  {ProjectCode}_UI_Operations/src/  ← Operational user-facing UI
  {ProjectCode}_UI_Admin/src/       ← Optional admin UI
  {ProjectCode}_Reporting/src/      ← Optional reporting lifecycle layer
  {ProjectCode}_TestData/src/       ← Optional synthetic test-data lifecycle layer
  (no _Config directory by default)
```

---

## When AI Suggests Code or Configuration

- All Dataverse table logical names use prefix: `{prefix}_tablename`.
- All column logical names use prefix: `{prefix}_columnname`.
- Primary name column pattern: `{prefix}_{entityname}name` (e.g., `sys_assetname`).
- Primary key column pattern: `{prefix}_{entityname}id` (e.g., `sys_assetid`).
- Environment URLs should match the target cloud; for GCC High examples, use `.crm.microsoftdynamics.us`.
- Flow expressions referencing tables use the logical name with prefix.
- PAC CLI auth commands should include the target cloud flag when the environment needs one; for GCC High examples, use `--cloud UsGovHigh`.
- Solution names always follow `{ProjectCode}_{Layer}`; operational UI is `{ProjectCode}_UI_Operations`, not `_UI_User`.
- Web resources that support data integrity, validation, or Core forms belong in `_Core`; UX-only web resources belong in UI.

---

## Reference Documents in This Repository

- [LP-ALM.md](../LP-ALM.md) — Full methodology
- [docs/lp-alm-refinement-plan.md](../docs/lp-alm-refinement-plan.md) — Refined model source of truth
- [.ai/layers.md](layers.md) — Quick layer decision reference
- [.ai/schema.md](schema.md) — Table and column inventory
- [.ai/conventions.md](conventions.md) — Naming conventions detail
- [docs/security-role-matrix-template.md](../docs/security-role-matrix-template.md) — Privilege matrix
- [docs/onboarding-checklist.md](../docs/onboarding-checklist.md) — New team onboarding
- [docs/component-placement-decision-tree.md](../docs/component-placement-decision-tree.md) — Where does X go?
