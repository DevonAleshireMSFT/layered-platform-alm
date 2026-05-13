# Project AI Context — LP-ALM Reference Implementation

> This file is the primary AI grounding document for this repository.
> Load this file first when using GitHub Copilot, Azure AI Foundry, or any AI assistant
> to work on this project. All suggestions should align with the conventions below.

---

## Project Identity

| Field | Value |
|---|---|
| **Project Code** | `{ProjectCode}` — replace with actual project code (e.g., `SYSTRK`) |
| **Publisher Display Name** | `{Project Name} Platform` |
| **Publisher Unique Name** | `{projectname}platform` |
| **Publisher Prefix** | `{prefix}` — 2–5 char lowercase (e.g., `sys`) |
| **Methodology** | Layered Power Platform ALM (LP-ALM) v1.0 |

---

## Environment Inventory

| Environment | Type | URL | Deployment Method |
|---|---|---|---|
| Dev | Unmanaged sandbox | `https://{org}-dev.crm.microsoftdynamics.us` | Manual / PAC CLI |
| Test | Managed | `https://{org}-test.crm.microsoftdynamics.us` | Azure DevOps pipeline |
| Prod | Managed | `https://{org}.crm.microsoftdynamics.us` | Azure DevOps pipeline |

**Cloud:** GCC High — all URLs use `.crm.microsoftdynamics.us`  
**Admin Center:** `https://gcc.admin.powerplatform.microsoft.us`

---

## The Five Layers (deploy in this order)

| Order | Solution Name | Purpose | Source Control | Pipeline |
|---|---|---|---|---|
| 1 | `{ProjectCode}_Security` | Security roles, field security profiles | ✅ Yes | ✅ Yes |
| 2 | `{ProjectCode}_Core` | All Dataverse schema (tables, columns, views, forms) | ✅ Yes | ✅ Yes |
| 3 | `{ProjectCode}_Config` | Environment variable values | ❌ **Never** | ❌ **Never** |
| 4 | `{ProjectCode}_Automation` | Power Automate flows, connection references | ✅ Yes | ✅ Yes |
| 5 | `{ProjectCode}_UI` | Model-driven apps, canvas apps, site maps | ✅ Yes | ✅ Yes |

---

## Critical Rules — Do Not Violate These

1. **`_Config` is never committed to source control.** Never. Not even temporarily. Not even as a test. The `.gitignore` excludes it by pattern.

2. **`_UI` cannot contain schema.** If you see a table or column inside the `_UI` solution, it must be moved to `_Core`. This is structural, not stylistic.

3. **`_Security` deploys first.** Always. In every environment. The pipeline enforces this with dependency gates.

4. **Connection references use service accounts, not personal credentials.** The connection binding in the environment uses a service account. No personal email address should appear in a connection reference.

5. **Upper environments (Test, Prod) receive managed solutions only.** Dev receives unmanaged. Do not deploy a managed solution to Dev.

6. **The pipeline service principal requires the System Administrator built-in role** (not a custom role) to deploy security roles. This is a Dataverse platform constraint (`prvWriteRole`).

---

## Key Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Security roles deploy first | Yes — structural control | Access control must precede schema creation; eliminates window where tables exist without governance |
| `_Config` excluded from source control | Yes — absolute | Zero-secrets-in-repo guarantee; prevents environment topology exposure |
| Managed solutions in Test/Prod | Yes | Prevents ad-hoc customization bypass; supports CM-3 (change control) |
| Per-layer pipelines + orchestration | Yes | Enables independent layer hotfixes + coordinated full deploys |
| Service principal auth only | Yes | GCC High does not support interactive login for pipelines |
| Single publisher per project | Yes | Prevents namespace collisions; schema prefix is consistent |

---

## Source Control Layout

```
.ai/              ← AI context (this directory)
.gitignore        ← Power Platform exclusions including _Config
LP-ALM.md         ← Full methodology document
README.md         ← Project overview
docs/             ← Security role matrix, environment register, onboarding
pipelines/        ← Azure DevOps YAML files
solutions/
  {ProjectCode}_Security/src/    ← Unpacked Security layer
  {ProjectCode}_Core/src/        ← Unpacked Core layer
  {ProjectCode}_Automation/src/  ← Unpacked Automation layer
  {ProjectCode}_UI/src/          ← Unpacked UI layer
  (no _Config directory)
```

---

## When AI Suggests Code or Configuration

- All Dataverse table logical names use prefix: `{prefix}_tablename`
- All column logical names use prefix: `{prefix}_columnname`
- Primary name column pattern: `{prefix}_{entityname}name` (e.g., `sys_assetname`)
- Primary key column pattern: `{prefix}_{entityname}id` (e.g., `sys_assetid`)
- Environment URLs always end in `.crm.microsoftdynamics.us` for this project
- Flow expressions referencing tables use the logical name with prefix
- PAC CLI commands must include `--cloud UsGovHigh` for auth commands
- Solution names always follow `{ProjectCode}_{Layer}` pattern

---

## Reference Documents in This Repository

- [LP-ALM.md](../LP-ALM.md) — Full methodology (all 11 sections)
- [.ai/layers.md](layers.md) — Quick layer decision reference
- [.ai/schema.md](schema.md) — Table and column inventory
- [.ai/conventions.md](conventions.md) — Naming conventions detail
- [docs/security-role-matrix-template.md](../docs/security-role-matrix-template.md) — Privilege matrix
- [docs/onboarding-checklist.md](../docs/onboarding-checklist.md) — New team onboarding
- [docs/component-placement-decision-tree.md](../docs/component-placement-decision-tree.md) — Where does X go?
