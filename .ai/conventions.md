# LP-ALM Naming Conventions

> AI context file. Use this when generating table names, column names, solution names,
> role names, or any other identifier in this project.

---

## Publisher

| Field | Value |
|---|---|
| Display Name | `{Project Name} Platform` |
| Unique Name | `{projectname}platform` |
| Prefix | `{prefix}` (2–5 lowercase alpha chars, e.g., `sys`) |
| Choice Value Prefix | `{numeric prefix}` (e.g., `10000`) |

**Rules:**
- The prefix is lowercase alpha characters only — no numbers, no underscores, no hyphens
- Do not change the prefix after deployment — it is schema-breaking
- All custom tables, columns, and option sets use this prefix

---

## Table Names

```
Format:  {prefix}_{entity_name}
Example: sys_asset
         sys_workorder
         sys_location
         sys_technician
```

- Use singular noun (not plural)
- Lowercase, underscores only
- Avoid abbreviations unless they are well-established in the domain

---

## Column Names

```
Format:  {prefix}_{column_name}
Example: sys_assetname
         sys_serialnumber
         sys_assignedtechnicianid   (lookup column)
         sys_workorderstatus        (choice column)
         sys_estimatedcompletiondate
```

- Lowercase, no underscores within the descriptor (the prefix underscore is the only one)
- Lookup columns end in `id` (system convention — Dataverse appends this automatically for lookups)

---

## Primary Name Column Convention

Use `{prefix}_{entityname}name` for the primary name column:

```
Table:               sys_asset
Primary Name Column: sys_assetname   ← this is the "name" field shown in lookups
Primary Key Column:  sys_assetid     ← system-generated GUID, do not modify
```

This prevents confusion between the primary key (`id`) and the display name field (`name`).

---

## Relationship Names

```
Format:  {prefix}_{parent_entity}_{child_entity}_{cardinality}
Example: sys_asset_workorder_1N     (one asset → many work orders)
         sys_workorder_technician_N1 (many work orders → one technician)
         sys_asset_tag_NN            (many assets ↔ many tags)
```

---

## Option Set (Choice) Names

```
Local option set (one table only):
  Format:  {prefix}_{entityname}_{columnname}
  Example: sys_asset_status
           sys_workorder_priority

Global option set (shared across tables):
  Format:  {prefix}_{descriptivename}
  Example: sys_prioritylevel
           sys_approvalstatus
```

---

## Solution Names

```
Format:   {ProjectCode}_{Layer}

Examples:
  SYSTRK_Security
  SYSTRK_Core
  SYSTRK_Automation
  SYSTRK_UI_Operations
  SYSTRK_UI_Admin
```

- `ProjectCode` is uppercase, 3–8 characters
- Do not include environment names in solution names
- The solution name is constant across Dev, Test, and Prod
- Use `{ProjectCode}_UI_Operations` for the user-facing operational UI solution
- Use `{ProjectCode}_UI_Admin` only for admin or elevated-access UI capabilities
- Do not create a committed `{ProjectCode}_Config` solution for environment variable values
- Optional governed layers still follow `{ProjectCode}_{Layer}` (for example, `{ProjectCode}_Integration`, `{ProjectCode}_Reporting`, `{ProjectCode}_TestData`)

**Unique names (API/programmatic):**
```
systrk_security
systrk_core
systrk_automation
systrk_ui_operations
systrk_ui_admin
```

### Environment Variable Definitions and Values

- Environment variable **definitions** (schema name, type, default) live in `{ProjectCode}_Core`
- Environment variable **values** are deployment-controlled data supplied through the Config Gate
- Values are never committed to source control, never published as artifacts, and never included in pipeline solution references
- A dedicated unmanaged `{ProjectCode}_Config` solution is only an optional audit-anchor alternative when justified; it is manually applied and never committed

---

## Security Role Names

```
Format:   {ProjectCode} - {PersonaOrFunction}

Examples:
  SYSTRK - Administrator
  SYSTRK - Contributor
  SYSTRK - Read Only
  SYSTRK - Support
  SYSTRK - Automation Service
```

- Use display name format (spaces, title case)
- Dash separator between project code and role name
- Do not include environment names
- Do not prefix with publisher prefix (roles are display-named, not schema-named)

---

## Environment Names and URLs

```
Format:   {OrgCode}-{Environment}
Examples:
  AGENCYNAME-Dev
  AGENCYNAME-Test
  AGENCYNAME-Prod

GCC High URL examples:
  Dev:  https://agencyname-dev.crm.microsoftdynamics.us
  Test: https://agencyname-test.crm.microsoftdynamics.us
  Prod: https://agencyname.crm.microsoftdynamics.us
```

Do not hardcode environment URLs in source control. Store them as Azure DevOps variable group values or deployment-controlled Config Gate values.

For sovereign or regulated environments, use the URL domain and PAC CLI cloud flag that match the tenant. GCC High / IL4 / IL5 contexts are examples where `.crm.microsoftdynamics.us` and `--cloud UsGovHigh` are commonly used.

---

## Azure DevOps Variable Group Names

```
{ProjectCode}-Common    (project-wide, non-secret variables)
{ProjectCode}-Test      (Test environment variables and secrets)
{ProjectCode}-Prod      (Prod environment variables and secrets)
```

---

## Branch Names

```
main          (production-aligned, protected)
test          (test-aligned, protected)
feature/{description}   (short-lived, PR to test)
hotfix/{description}    (emergency fix, PR to main)
```

---

## Pipeline File Names

```
pipelines/deploy-security.yml
pipelines/deploy-core.yml
pipelines/deploy-automation.yml
pipelines/deploy-ui.yml
pipelines/deploy-all.yml
pipelines/pr-validation.yml
```

---

## Legacy Prefix Handling

If this project has a pre-existing prefix that differs from what a new project would choose:

- **Existing prefix:** `{existing_prefix}` (retained for schema compatibility)
- **Reason for retention:** Existing schema with this prefix; renaming is a destructive operation
- **Action:** All new components continue to use `{existing_prefix}`. No second publisher.

Document any such exception here so AI tools do not suggest a different prefix.
