# LP-ALM Layer Quick Reference

> Use this file to answer: **"Where does this component go?"**
> LP-ALM is mandatory ordered invariants plus optional governed layers.
> For full detail, see `LP-ALM.md` and `docs/lp-alm-refinement-plan.md`.

---

## Non-Negotiable Ordering

1. `{ProjectCode}_Security` deploys first.
2. `{ProjectCode}_Core` deploys second and is the only schema layer.
3. Config Gate validates deployment-controlled values and bindings after Core; it is not a solution.
4. Optional layers deploy only when justified by artifacts and lifecycle needs.

---

## Architecture Tiers

| Tier | Baseline shape | Notes |
|---|---|---|
| Minimum | `_Security` + `_Core` + `_UI_Operations` | Allowed only when there are no external integrations, no cross-boundary/CUI data movement, and no privileged admin UI. |
| Standard | Minimum + `_Automation` | Use when flows, connectors, connection references, scheduled jobs, or automation assets exist. |
| Enterprise | Standard + `_Integration` + multiple UIs as warranted | Use for shared integrations, cross-system orchestration, external ATO dependencies, CUI exchange, or admin separation. |

**Secure-environment floor:** Security is separate and first; Core is the only schema layer; UI is schema-free; Test/Prod are managed-only; configuration values and secrets are never committed. Sovereign and regulated contexts such as GCC High, IL4, and IL5 are examples where these controls are often expected.

---

## Mandatory Layer: `_Security`

**One-line purpose:** Establish access control before anything else exists.

**Belongs here:**
- Custom security roles
- Field security profiles
- Column security profile-to-column bindings
- Protected access structures that must precede schema deployment

**Does NOT belong here:**
- Tables or columns (→ `_Core`)
- Flows (→ `_Automation`)
- Apps (→ `_UI_Operations` or `_UI_Admin`)
- Users, teams, business units (→ environment data, not solution components)

**Deploys:** First, always, in every environment
**Source control:** ✅ Yes
**Pipeline:** ✅ Yes (uses a System Administrator service principal for `prvWriteRole`)
**Solution type in upper environments:** Managed

---

## Mandatory Layer: `_Core`

**One-line purpose:** Define all Dataverse schema — the single source of truth for data structure.

**Belongs here:**
- Custom tables
- Custom columns (all types)
- Table relationships (1:N, N:1, N:N)
- Global choices / option sets
- System views (active, inactive, lookup, associated)
- Main forms, quick view forms, quick create forms, card forms
- Charts
- Table keys (alternate keys)
- Calculated and rollup column definitions
- Environment variable **definitions** only
- Web resources used by Core forms or tied to validation, integrity, or schema-adjacent behavior

**Does NOT belong here:**
- Security roles (→ `_Security`)
- Environment variable **values** (→ Config Gate)
- Flows (→ `_Automation`)
- Apps, app site maps, app dashboards (→ `_UI_Operations` / `_UI_Admin`)
- UX-only web resources (→ UI)

**Deploys:** Second (after `_Security`)
**Source control:** ✅ Yes
**Pipeline:** ✅ Yes
**Solution type in upper environments:** Managed

---

## Config Gate (Default, Not a Solution)

**One-line purpose:** Confirm environment-specific values and connection bindings are present before dependent layers activate.

**Handled here:**
- Environment variable current values
- Connection bindings
- Non-secret environment configuration register metadata
- Secret-backed deployment inputs from approved stores / variable groups
- Connection references SHOULD use dedicated service accounts by default. If service accounts are unavailable, use a least-privilege delegated identity with documented ownership, credential rotation, approval authority, and environment-register evidence.

**Rules:**
- `_Config` is not required and must not be presented as a mandatory layer.
- Values, secrets, tenant identifiers, connection bindings, and raw configuration values are never committed.
- The environment configuration register stores metadata only.
- Optional unmanaged `{ProjectCode}_Config` is allowed only as a documented high-control / audit-anchor alternative; it is manually applied, never committed, never referenced by pipelines, and must not contain secrets.

**Runs:** After `_Core`, before `_Integration`, `_Automation`, or any UI that consumes values / bindings
**Source control:** ❌ Values never
**Pipeline:** ✅ Gate / validation / ephemeral settings only, never `_Config` artifacts

---

## Optional Layer: `_Integration`

**One-line purpose:** Isolate shared or independently governed integration assets.

**Create when:**
- Integrations are numerous, shared, separately owned, or independently released
- Cross-boundary services, CUI exchange, external ATO dependencies, or separately governed service connections exist
- Connectors or connection references become platform assets consumed by multiple layers

**Does NOT belong here:**
- General app flows with no shared integration lifecycle (→ `_Automation`)
- Schema (→ `_Core`)
- UI artifacts (→ UI)

**Deploys:** After `_Core`; Config Gate before activation when values / bindings are needed
**Source control:** ✅ Yes
**Pipeline:** ✅ Yes
**Solution type in upper environments:** Managed

---

## Optional Layer: `_Automation`

**One-line purpose:** Contain Power Automate and automation runtime assets when they exist.

**Belongs here:**
- Cloud flows (automated, instant, scheduled)
- Connection references not split into `_Integration`
- Business process flows (if workflow-driven)
- Desktop flows
- Custom connectors (if project-owned and not integration-layer assets)
- Scheduled jobs and data-processing logic

**Does NOT belong here:**
- Table or column definitions (→ `_Core`)
- Canvas apps / model-driven apps (→ UI)
- Security roles (→ `_Security`)
- Environment variable definitions (→ `_Core`)
- Environment variable values (→ Config Gate)

**Deploys:** After `_Core`; after `_Integration` when consuming shared integration components; Config Gate before activation
**Source control:** ✅ Yes
**Pipeline:** ✅ Yes
**Solution type in upper environments:** Managed

---

## Optional UI Layers: `_UI_Operations` and `_UI_Admin`

**One-line purpose:** Contain application experience components — render data, define no schema.

**Use `{ProjectCode}_UI_Operations` for:**
- User-facing operational model-driven apps
- Canvas apps
- Custom pages
- Operational app site maps
- Shared operational dashboards
- PCF controls
- UX-only web resources

**Use `{ProjectCode}_UI_Admin` when admin capability has distinct:**
- Ownership
- Release cadence
- Deployment target
- Persona / privilege boundary
- Blast radius or audit expectations

**Does NOT belong in any UI solution:**
- Tables, columns, relationships, choices, keys, or structural data definitions (→ `_Core`)
- Security roles (→ `_Security`)
- Flows or connection references (→ `_Automation` / `_Integration`)
- Environment variable definitions (→ `_Core`)
- Environment variable values (→ Config Gate)
- Integrity/schema-adjacent web resources used by Core forms (→ `_Core`)

**Deploys:** After declared dependencies; both UI solutions can deploy independently in the UI phase
**Source control:** ✅ Yes
**Pipeline:** ✅ Yes
**Solution type in upper environments:** Managed
**Warning:** If solution checker or `git diff` shows `Entities/` content inside UI, stop and move it to `_Core`.

---

## Optional Layer: `_Reporting`

**One-line purpose:** Contain substantial reporting artifacts with a distinct lifecycle.

**Create when:** Reporting artifacts need separate ownership, release cadence, audit review, or governed distribution.

**Dependencies:** `_Core`; `_Security` when row-level access or governed distribution is needed.
**Source control:** ✅ Yes
**Pipeline:** ✅ Yes, if promoted as a managed solution

---

## Optional Layer: `_TestData`

**One-line purpose:** Contain synthetic test datasets and validation assets with a distinct lifecycle.

**Create when:** Repeatable test data or validation assets are substantial enough to govern separately.

**Rules:** Never include real sensitive production data unless explicitly authorized, documented, and controlled.

**Dependencies:** `_Security`, `_Core`; `_Automation` optional.
**Source control:** ✅ Yes for synthetic assets only
**Pipeline:** Optional, depending on environment strategy

---

## Layer Decision Model

1. **Always create `_Security`.** Roles, field security profiles, protected access structures.
2. **Always create `_Core`.** All schema: tables, columns, relationships, views, forms, keys, choices, charts, and environment variable definitions.
3. **Default to the Config Gate; do not mandate `_Config`.** Values and connection bindings are deployment-controlled data and never committed. Optional unmanaged `_Config` is allowed only with documented high-control justification.
4. **Create `_Automation` when automation exists.** Flows, custom connectors, connection references, scheduled jobs, and data-processing logic.
5. **Create `_UI_Operations` when user-facing operational artifacts exist.** Apps, dashboards, site maps, PCF, custom pages, and UX web resources.
6. **Create `_UI_Admin` only for distinct ownership, release cadence, deployment target, persona boundary, or blast radius.**
7. **Create `_Integration` only when integrations are shared, numerous, separately owned, independently released, or government-governed as cross-boundary services.**
8. **Create `_Reporting` or `_TestData` only when artifacts are substantial and have an independent lifecycle.**

---

## Updated Dependency Matrix

| Solution / Gate | Depends on | Notes |
|---|---|---|
| `_Security` | Nothing | First deployed layer in every tier. Can deploy to an empty environment. |
| `_Core` | `_Security` | Owns all schema and environment variable definitions. |
| Config Gate | `_Security`, `_Core` | Default pattern. Not a solution. Values and bindings must exist before dependent layers activate. |
| `_Integration` (optional) | `_Security`, `_Core`; Config Gate before activation when values / bindings are needed | Use for shared or independently governed integrations. |
| `_Automation` (optional) | `_Security`, `_Core`; `_Integration` when consuming shared integration components; Config Gate before activation | Use for flows, connection references, custom connectors, and scheduled jobs. |
| `_UI_Operations` | `_Security`, `_Core`; `_Automation` optional; Config Gate when consuming values / bindings | Operational user-facing applications. Must remain schema-free. |
| `_UI_Admin` (optional) | `_Security`, `_Core`; `_Automation` optional; Config Gate when consuming values / bindings | Admin UI, independent of `_UI_Operations`; use when criteria justify split. |
| `_Reporting` (optional) | `_Core`; `_Security` when row-level access or governed distribution is needed | Use for substantial reporting artifacts with a distinct lifecycle. |
| `_TestData` (optional) | `_Security`, `_Core`; `_Automation` optional | Use only for synthetic test data and validation assets unless production data use is authorized. |

---

## Quick Decision Matrix

| I have a... | It goes in... |
|---|---|
| Custom table | `_Core` |
| Custom column | `_Core` |
| Table relationship | `_Core` |
| System view | `_Core` |
| Form (main, quick view, quick create) | `_Core` |
| Global choice / option set | `_Core` |
| Chart | `_Core` |
| Environment variable definition | `_Core` |
| Web resource used by Core forms, validation, or integrity behavior | `_Core` |
| Security role | `_Security` |
| Field security profile | `_Security` |
| Environment variable value | Config Gate (deployment data, never committed) |
| Connection binding | Config Gate / environment data, never committed |
| Cloud flow (automated/instant/scheduled) | `_Automation` |
| Business process flow | `_Automation` unless purely UI-owned and justified otherwise |
| Custom connector, shared service connection, cross-boundary integration | `_Integration` when shared/governed; otherwise `_Automation` |
| Model-driven operational app | `_UI_Operations` |
| Canvas operational app | `_UI_Operations` |
| Admin app | `_UI_Admin` when split criteria apply |
| App site map | Matching UI solution |
| Shared dashboard | Matching UI solution or `_Reporting` when reporting lifecycle warrants |
| PCF control | Matching UI solution unless schema-adjacent dependency requires `_Core` |
| Web resource that is display/rendering/UX-only | Matching UI solution |
| Reporting artifact with independent lifecycle | `_Reporting` |
| Synthetic test dataset / validation asset | `_TestData` |
| User record | Not a solution component — environment data |
| Team record | Not a solution component — environment data |
| Business unit | Not a solution component — environment data |
