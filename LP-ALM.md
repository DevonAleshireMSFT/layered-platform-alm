---
layout: default
title: LP-ALM Methodology
nav_order: 2
description: "Complete 11-section methodology reference: layer definitions, security architecture, PAC CLI workflow, ADO pipelines, security role design, and environment strategy."
permalink: /methodology/
render_with_liquid: false
---

# Layered Power Platform ALM (LP-ALM)
## A Security-First Decomposition Methodology for Enterprise Power Platform Deployments

**Version:** 1.0  
**Date:** May 2026  
**Applicability:** Microsoft Power Platform / Dataverse — Commercial, GCC, GCC High (FedRAMP)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Layer Definitions](#2-layer-definitions)
3. [Security Architecture Rationale](#3-security-architecture-rationale)
4. [Publisher and Naming Conventions](#4-publisher-and-naming-conventions)
5. [Source Control Structure](#5-source-control-structure)
6. [PAC CLI Workflow](#6-pac-cli-workflow)
7. [Azure DevOps Pipeline Architecture](#7-azure-devops-pipeline-architecture)
8. [Security Role Design Guidance](#8-security-role-design-guidance)
9. [Environment Strategy](#9-environment-strategy)
10. [Onboarding Guide for New Teams](#10-onboarding-guide-for-new-teams)
11. [Methodology Positioning](#11-methodology-positioning)
12. [Platform Prerequisites & Complementary Guidance](#12-platform-prerequisites--complementary-guidance)

**Appendices**
- [Appendix A: Azure Integration Layer Guidance](#appendix-a-azure-integration-layer-guidance)

---

## 1. Executive Summary

### 1.1 What LP-ALM Is

Layered Power Platform ALM (LP-ALM) is a structured application lifecycle management framework for Microsoft Power Platform that decomposes solutions into five discrete, ordered deployment layers: Security, Core, Config, Automation, and UI. Each layer has a defined scope, deployment method, source control treatment, and dependency contract with adjacent layers.

LP-ALM exists because monolithic Power Platform solutions — a single solution containing security roles, data schema, flows, environment variables, connection references, and app components — create a class of problems that compound over time: coupled deployments where a UI change requires a full schema re-import, pipeline secrets exposure from environment-specific values committed to source control, security role gaps when tables are created before access controls exist, and merge conflicts across teams when all components share a single solution artifact.

### 1.2 Who It Is For

LP-ALM is designed for:

- **Enterprise Power Platform teams** managing solutions across multiple environments (Dev, Test, Prod)
- **Government and regulated-industry deployments** operating under FedRAMP, CMMC, FISMA, or HIPAA compliance frameworks
- **Platform architects** building repeatable, auditable delivery pipelines using Azure DevOps and PAC CLI
- **Consulting teams** delivering Power Platform solutions to clients who require documentation of security controls, change management processes, and pipeline architecture

LP-ALM is not appropriate for single-environment prototypes, low-code citizen developer projects without a dedicated ALM team, or solutions that will never leave a development environment.

### 1.3 Core Value Proposition vs. Monolithic Development

| Dimension | Monolithic ALM | LP-ALM |
|---|---|---|
| Deployment unit | Single solution (everything) | Five targeted solutions |
| Security posture | Security roles deployed with schema | Security exists before schema |
| Secrets exposure | Environment values in pipelines or source | `_Config` excluded from both |
| Blast radius | Full solution reimport for any change | Layer-scoped change and rollback |
| Team parallelism | One solution, merge conflicts | Layers owned independently |
| Schema protection | Schema can creep via UI solution | `_UI` structurally cannot contain schema |
| Compliance audit | Point-in-time export of monolith | Per-layer, independently auditable artifacts |
| Partial deployment | All-or-nothing | Deploy only the layers that changed |

### 1.4 Security Architecture Statement (ATO/Security Plan Language)

> The Layered Power Platform ALM methodology implements a defense-in-depth deployment architecture for Microsoft Power Platform. Security roles and field security profiles are established as the first deployment action in every environment, ensuring that access control structures precede the creation of any data schema, application logic, or user interface. Environment-specific configuration values, including connection strings, shared secret references, and tenant-specific identifiers, are classified as configuration data and are explicitly excluded from source control and automated pipelines. All upper-environment deployments use managed solutions, preventing ad-hoc customization and enforcing change control through the pipeline. Pipeline execution uses service principal application users with the minimum required privileges for each layer. This architecture directly implements NIST SP 800-53 controls AC-2, AC-3, CM-2, CM-3, and SA-3, and is designed to support FedRAMP Moderate and High authorization requirements in Microsoft Azure Government (GCC High) environments.

---

## 2. Layer Definitions

The five LP-ALM layers deploy in a fixed sequence. This sequence is not a convention — it is a dependency contract. Each layer assumes the preceding layers are deployed and stable.

**Deployment order:** `_Security` → `_Core` → `_Config` → `_Automation` → `_UI`

> **Note:** `_Config` is deployed manually between `_Core` and `_Automation`. It is never pipeline-automated. The pipeline sequence is therefore: `_Security` → `_Core` → *(manual `_Config`)* → `_Automation` → `_UI`.

---

### 2.1 Layer 1: `_Security`

**Purpose:** Establish all access control structures before any data schema, business logic, or application component exists in the environment.

**Scope:** This layer owns everything that controls who can do what — but contains no data definitions, no application code, and no user-facing components.

#### Canonical Component List

**Belongs in `_Security`:**
- Security roles (all custom roles for the project)
- Field security profiles
- Owner team shell records (the team entity definition pattern, not the team data)
- Column security profile assignments (the profile-to-column binding, not the column itself)

**Does NOT belong in `_Security`:**
- Any table definition (tables belong in `_Core`)
- Any column definition (columns belong in `_Core`)
- Business process flows (belong in `_Automation` or `_UI` depending on trigger)
- Users, teams, or system users (these are environment data, not solution components)
- Business unit structure (environment configuration, not a solution component)

#### Decision Rules

```
Is this component a security role or variation of one?        → _Security
Is this a field security profile?                             → _Security
Is this a team template (not team data)?                      → _Security
Does this component grant or restrict access to a data entity? → _Security
Does this component define a column, table, relationship, or view? → _Core (not _Security)
```

#### Dependencies

`_Security` has no dependencies on other LP-ALM layers. It is the only layer that can deploy to a completely empty environment.

#### Deployment Method

| Environment | Solution Type | Mechanism |
|---|---|---|
| Dev | Unmanaged | PAC CLI import or manual |
| Test | Managed | Azure DevOps pipeline |
| Prod | Managed | Azure DevOps pipeline |

#### Source Control

**Yes.** All components in `_Security` are committed to source control. Security role XML definitions and field security profile definitions are environment-agnostic — they describe privilege structures, not environment-specific values.

#### Special Considerations

The pipeline service principal must hold the **System Administrator** built-in role (not a custom role) in the target environment. This is required because deploying security roles requires the `prvWriteRole` privilege, which cannot be granted to a custom security role — it is only available to System Administrator. This is a Dataverse platform constraint, not an LP-ALM design decision.

---

### 2.2 Layer 2: `_Core`

**Purpose:** Define the complete Dataverse data schema for the project. This layer is the single source of truth for all tables, columns, relationships, views, and forms.

**Scope:** This layer owns all schema definitions. Nothing else does. Any component that defines a data structure belongs here.

#### Canonical Component List

**Belongs in `_Core`:**
- Custom tables (all of them)
- Custom columns (all types: text, number, choice, lookup, polymorphic lookup, file, image)
- Table relationships (1:N, N:1, N:N)
- Global option sets (shared choice columns)
- System views (all views: active, inactive, lookup, associated)
- Main forms, quick view forms, quick create forms, card forms
- Charts
- Table keys (alternate keys)
- Calculated and rollup column definitions
- Environment variable definitions (the schema — name, type, default value)

**Does NOT belong in `_Core`:**
- Security roles (belong in `_Security`)
- Power Automate flows (belong in `_Automation`)
- Connection references (belong in `_Automation`)
- Environment variable current values (belong in `_Config`)
- Canvas apps (belong in `_UI`)
- Model-driven apps (belong in `_UI`)
- Site maps (belong in `_UI`)
- Dashboards (belong in `_UI`)

> **Environment Variable Definitions vs. Values:** The environment variable *definition* (schema — name, type, default value) belongs in `_Core`. The environment variable *value* (the actual value for a specific environment) belongs in `_Config`. These are separate solution components in Dataverse and must be split accordingly.

#### Decision Rules

```
Does this component define a table, column, relationship, or view?  → _Core
Does this component define a form?                                   → _Core
Does this component define how data is structured or stored?         → _Core
Does this component define how data is accessed or secured?          → _Security
Does this component define how data is processed or moved?           → _Automation
Does this component define how data is displayed in an app?          → _UI
Is this an environment variable definition (schema only)?            → _Core
Is this an environment variable value?                               → _Config
```

#### Dependencies

`_Core` depends on `_Security`. Security roles must exist before tables are created, because table creation triggers permission-related platform operations.

#### Deployment Method

| Environment | Solution Type | Mechanism |
|---|---|---|
| Dev | Unmanaged | PAC CLI import or manual |
| Test | Managed | Azure DevOps pipeline |
| Prod | Managed | Azure DevOps pipeline |

#### Source Control

**Yes.** All schema definitions are committed. Schema is environment-agnostic.

---

### 2.3 Layer 3: `_Config`

**Purpose:** Carry environment-specific values that cannot be environment-agnostic. This layer is the controlled exception to the standard LP-ALM pattern.

**Scope:** Environment variable current values, and only environment variable current values. Nothing else.

#### Canonical Component List

**Belongs in `_Config`:**
- Environment variable current values (the actual value, not the definition)
- Any component that differs between Dev, Test, and Prod by necessity

**Does NOT belong in `_Config`:**
- Environment variable definitions (belong in `_Core`)
- Security roles (belong in `_Security`)
- Flows (belong in `_Automation`)
- Any schema component

#### Decision Rules

```
Is this value different in Dev vs. Test vs. Prod?             → _Config
Is this a secret, API key, URL, or tenant identifier?         → _Config
Is this a schema definition?                                  → _Core (not _Config)
Is this a flow?                                               → _Automation
```

#### Source Control Exclusion

**`_Config` is NEVER committed to source control. This is non-negotiable.**

The rationale: environment variable values frequently contain tenant-specific identifiers, endpoint URLs, and other values that differ between sovereign cloud environments (commercial vs. GCC High). Committing these values risks:

1. Exposing tenant topology information in a potentially public or audited repository
2. Accidentally deploying commercial values into GCC High environments (or vice versa)
3. Creating a false expectation that source control is the authoritative source for configuration

The authoritative source for `_Config` values is the environment itself (via manual entry) or a secrets management system (Azure Key Vault) — not the repository.

#### Deployment Method

**Manual only. No pipeline automation.**

The deployment process is:
1. Export from a reference environment (typically Dev or a config-reference environment)
2. Modify values for the target environment
3. Import manually by a person with access to the target environment
4. Document the values in the environment's configuration management record (not in source control)

#### Pipeline Treatment

Pipelines must not reference, import, or validate `_Config` in any way. No pipeline variable should contain `_Config` values. If a pipeline needs environment-specific values (e.g., a connection reference URL), those are passed as Azure DevOps variable group secrets — they are never read from the `_Config` solution file.

---

### 2.4 Layer 4: `_Automation`

**Purpose:** Contain all process automation: Power Automate flows, connection references, and environment variable definitions used by flows.

**Scope:** Automation logic only. No schema, no UI, no security definitions.

#### Canonical Component List

**Belongs in `_Automation`:**
- Cloud flows (all types: instant, automated, scheduled)
- Connection references
- Business process flows (if they drive workflow, not just UI)
- Desktop flows (if present)
- Custom connectors (if project-owned)

**Does NOT belong in `_Automation`:**
- Table definitions (belong in `_Core`)
- Canvas apps (belong in `_UI`)
- Model-driven apps (belong in `_UI`)
- Security roles (belong in `_Security`)
- Environment variable definitions (belong in `_Core`)
- Environment variable values (belong in `_Config`)

#### Decision Rules

```
Does this component process, transform, or move data?           → _Automation
Does this component respond to a trigger (create, update, schedule)? → _Automation
Does this component reference a connection?                     → _Automation
Is this a canvas app?                                          → _UI
Is this a model-driven app?                                    → _UI
Does this component define data structure?                      → _Core
```

#### Dependencies

`_Automation` depends on:
- `_Security` (flows run as users subject to security roles)
- `_Core` (flows reference tables and columns)
- `_Config` (connection reference values and environment variable values must be present)

**`_Config` must be manually deployed before `_Automation` is pipeline-deployed.** If environment variable values and connection references are not populated, flow activation will fail.

#### Deployment Method

| Environment | Solution Type | Mechanism |
|---|---|---|
| Dev | Unmanaged | PAC CLI import or manual |
| Test | Managed | Azure DevOps pipeline |
| Prod | Managed | Azure DevOps pipeline |

#### Source Control

**Yes.** Flow definitions, connection reference schemas, and environment variable definitions are all committed. Connection reference *values* (the actual credential binding) are populated via `_Config` and service account binding — not from source control.

#### Connection Reference Binding

Connection references in `_Automation` must be bound to service accounts, not personal credentials. When the solution is imported to Test or Prod:

1. The connection reference schema is imported as part of the managed solution
2. The connection (the actual credential binding) must be created in the target environment using a service account
3. This binding is applied via a post-import step using PAC CLI or the Power Platform Admin Center
4. Personal credential connections are never used — they fail when the user's credentials expire or the user leaves

> **GCC High Note:** Connection URLs in GCC High use `.crm.microsoftdynamics.us` instead of `.crm.dynamics.com`. Service account connections must be created with the correct sovereign cloud endpoint. The environment URL must be explicitly specified in all PAC CLI commands.

---

### 2.5 Layer 5: `_UI`

**Purpose:** Contain all user-facing application components. This layer renders data — it does not define it.

**Scope:** Application components only. `_UI` is structurally prohibited from containing schema. If a component introduces a new table or column, it belongs in `_Core`, not `_UI`.

#### Canonical Component List

**Belongs in `_UI`:**
- Model-driven apps
- Canvas apps
- Site maps
- Dashboards (shared dashboards, not personal)
- PCF (Power Apps Component Framework) controls
- App modules
- Web resources (JavaScript, HTML, images) that are app-facing
- Custom pages

**Does NOT belong in `_UI`:**
- Any table, column, or relationship definition (these belong in `_Core`)
- Security roles (belong in `_Security`)
- Flows (belong in `_Automation`)
- Connection references (belong in `_Automation`)
- Environment variables (definitions in `_Core`, values in `_Config`)

#### Decision Rules

```
Does this component render data to a user?                           → _UI
Is this a model-driven or canvas app?                               → _UI
Is this a dashboard or chart displayed in an app?                   → _UI
Does this component define a table or column?                        → _Core (not _UI — move it)
Is this a PCF control?                                              → _UI
Is this a web resource used by a form?
  If it defines behavior/validation tied to schema:                  → _Core
  If it is a display/rendering component:                           → _UI
```

#### The Schema Contamination Rule

`_UI` cannot introduce schema. This is enforced by architecture, not process:

- When building model-driven apps, new columns are added to `_Core` first, then the form in `_Core` is updated, then the app in `_UI` references the updated form
- If a solution checker or manual review finds a table or column component inside `_UI`, it must be moved to `_Core` before the pipeline runs

Violation of this rule causes a hard dependency failure: `_UI` would import a schema component, creating an unmanaged layer in a managed environment, breaking subsequent `_Core` updates.

#### Dependencies

`_UI` depends on all preceding layers:
- `_Security` (app access is controlled by security roles)
- `_Core` (apps reference tables, columns, views, and forms)
- `_Config` (apps may reference environment variables via connection references)
- `_Automation` (apps may trigger or display results of flows)

#### Deployment Method

| Environment | Solution Type | Mechanism |
|---|---|---|
| Dev | Unmanaged | PAC CLI import or manual |
| Test | Managed | Azure DevOps pipeline |
| Prod | Managed | Azure DevOps pipeline |

#### Source Control

**Yes.** All app definitions, site maps, dashboards, and PCF controls are committed.

---

## 3. Security Architecture Rationale

### 3.1 Security-First Deployment as a Structural Control

The conventional Power Platform ALM approach deploys security roles alongside or after data schema. This creates a window — often unclosed in test environments — where tables and columns exist without access control applied. In regulated environments, this window is a finding.

LP-ALM eliminates this window by architectural constraint. Security roles must exist in the environment before `_Core` deploys. The Dataverse platform itself enforces dependencies at import time: if `_Security` fails to import, `_Core` cannot proceed. This is not a process rule that can be bypassed by human error — it is a pipeline gate.

The consequence: in every LP-ALM environment, at every point in time, every data structure that exists has a corresponding access control structure that also exists. There is no moment where schema exists without governance.

### 3.2 The Config Exclusion Pattern: Eliminating Secrets Exposure

The `_Config` exclusion from source control addresses a specific, documented class of risk: secrets embedded in repository artifacts.

When environment variable values are committed to source control — either in solution files or as pipeline variable substitutions — those values become persistent, potentially searchable, and subject to repository access controls that are typically broader than the environment access controls. A developer with read access to the repository gains read access to production environment URLs, API keys, and tenant identifiers.

The LP-ALM config exclusion creates a zero-secrets-in-repo guarantee: the repository contains no value that is specific to any environment. A complete clone of the repository cannot yield a working connection to any environment. Credentials remain in the environments and in the secrets management system (Azure Key Vault), not in version control.

**This is not about paranoia — it is about attack surface reduction.** A repository is typically accessible to all developers. An environment is accessible only to those explicitly provisioned.

### 3.3 Managed Solution Enforcement in Upper Environments

In Test and Prod environments, all layers are deployed as managed solutions. The managed solution mechanism in Dataverse prevents:

1. **Ad-hoc customization bypass:** A developer cannot add a column to a managed table without going through the pipeline
2. **Untracked changes:** Any change applied outside the pipeline is visible as an "active layer" (unmanaged customization) and can be identified and removed
3. **Schema drift:** The managed solution guarantees that what is in source control matches what is in the environment

The combination of managed solutions and the layer architecture means each layer is independently lockable. A security role change requires only `_Security` to be reimported. A UI change requires only `_UI`. Neither can accidentally modify the other layer's components.

### 3.4 NIST 800-53 Control Mapping

| Control | Control Name | LP-ALM Implementation |
|---|---|---|
| AC-2 | Account Management | Service principal application users are provisioned and documented per environment. Personal credential binding is prohibited in Test and above. Connection references are bound to managed service accounts where agency policy permits; when service accounts are prohibited by IAM policy (common in DoD), a formal account provisioning request must document the non-personal credential approved for each environment tier. |
| AC-3 | Access Enforcement | Security roles deploy before schema (`_Security` first). Every table and column has a corresponding access control structure at all times. Managed solutions prevent unauthorized modification. |
| AC-6 | Least Privilege | Security roles are designed per persona with minimum required privileges. Pipeline service principal uses only the built-in System Administrator role (required for `prvWriteRole`) — no over-privileging beyond platform requirement. |
| CM-2 | Baseline Configuration | Source control contains the authoritative baseline for all four committed layers (`_Security`, `_Core`, `_Automation`, `_UI`). `_Config` is documented in configuration management records outside source control. |
| CM-3 | Configuration Change Control | All changes to committed layers go through pull request review and pipeline validation before deployment. No direct environment modification in Test/Prod is permitted (managed solution enforcement). |
| CM-6 | Configuration Settings | Environment-specific values are managed through `_Config` (manual, controlled) and Azure Key Vault (for pipeline secrets). No configuration values are hardcoded in pipeline definitions. |
| SA-3 | System Development Life Cycle | LP-ALM defines a structured SDLC for Power Platform: development in unmanaged Dev, validation in managed Test, promotion to managed Prod with independent layer sequencing and rollback capability. |
| SI-2 | Flaw Remediation | Layer isolation enables targeted remediation. A security role flaw requires only `_Security` reimport. A flow defect requires only `_Automation` reimport. Neither triggers a full solution deployment. |

### 3.5 GCC High Specific Requirements

GCC High (Azure Government, `.us` sovereign cloud) diverges from commercial Power Platform in several areas relevant to LP-ALM.

#### Application User Configuration

In GCC High, interactive login cannot be used for pipeline service connections. All pipeline authentication must use **application users** (service principals registered in Azure Government AD, not commercial Azure AD):

1. Register an app registration in the **Azure Government** tenant (`portal.azure.us`), not `portal.azure.com`
2. Create an application user in the GCC High Power Platform environment using the App ID
3. Assign the System Administrator built-in role to the application user
4. Use client secret or certificate authentication — never interactive/delegated auth

#### Environment URLs

GCC High environments use the `.crm.microsoftdynamics.us` domain:

```
# Commercial
https://yourorg.crm.dynamics.com

# GCC
https://yourorg.crm9.dynamics.com

# GCC High
https://yourorg.crm.microsoftdynamics.us
```

All PAC CLI commands must use the GCC High URL. All connection references must point to `.crm.microsoftdynamics.us` endpoints. Connection reference values committed to source control (definitions only) should not embed URLs — environment-specific URLs belong in `_Config`.

#### Connection References and Service Account Constraints

The best practice for connection references in all environments is a **non-interactive service account** — a licensed user account (not a service principal) with a stable credential, assigned only the `{ProjectCode} - Automation Service` security role, whose connections are used by all flows in that environment.

However, in many DoD agencies and classified programs, service accounts are restricted or prohibited by policy. Common constraints include CAC/PIV-only authentication requirements, zero-standing-access policies, or prohibitions on shared credentials for compliance reasons.

**LP-ALM's position on this constraint:**
- Service accounts are best practice and should be the default where agency policy permits
- Where service accounts are prohibited, personal credential bindings are acceptable **only in individual dev and Integration Dev environments**
- Test and above require a non-personal credential. If the agency's standard account provisioning process cannot provide a service account, the project team must formally request an IAM exception or equivalent managed identity, with documented approval authority
- This is an agency IAM policy question, not an LP-ALM design question — LP-ALM defines the technical requirement; the project resolves it through agency channels

See Section 5.6.9 for a full decision table and per-environment guidance on connection reference binding when service accounts are unavailable.

#### Power Platform Admin Center for GCC High

The GCC High admin center is at `https://gcc.admin.powerplatform.microsoft.us`. The commercial admin center (`admin.powerplatform.microsoft.com`) will not list GCC High environments.

#### PAC CLI Authentication for GCC High

```bash
# Authenticate to GCC High (specify cloud)
pac auth create \
  --name "GCCHigh-Prod" \
  --kind ServicePrincipal \
  --applicationId <app-id> \
  --clientSecret <secret> \
  --tenant <tenant-id> \
  --cloud UsGovHigh \
  --environment https://yourorg.crm.microsoftdynamics.us
```

---

## 4. Publisher and Naming Conventions

### 4.1 Publisher Setup

Every LP-ALM project requires a single, dedicated publisher. The publisher defines the prefix used for all custom schema components. Sharing publishers across projects is not recommended — it creates namespace collisions.

**Publisher configuration:**

| Field | Guidance |
|---|---|
| Display Name | Human-readable project name (e.g., "SYSTRK Platform") |
| Unique Name | Lowercase, no spaces, no special characters (e.g., `systrkplatform`) |
| Prefix | 2–5 character lowercase abbreviation (e.g., `sys`) |
| Choice Value Prefix | Numeric prefix aligned with prefix (e.g., `10000`) |

**Publisher naming rules:**
- Prefix must be lowercase alphabetic characters only (no numbers, no underscores)
- Prefix must be 2–5 characters
- The prefix is prepended to all custom table names, column names, and option set names in source control artifacts
- Do not change the prefix after initial deployment — this is a schema-breaking change

### 4.2 Schema Naming Rules

All custom components follow the publisher prefix convention:

**Tables:**
```
Format:  {prefix}_{entity_name}
Example: sys_asset, sys_workorder, sys_location
```

**Columns:**
```
Format:  {prefix}_{column_name}
Example: sys_assetname, sys_serialnumber, sys_assignedtechnicianid
```

**Primary Name Column Convention:**

The primary name column (the `_name` column) should be named `{prefix}_{entityname}name`:

```
Table:              sys_asset
Primary Name Column: sys_assetname
Primary Key Column:  sys_assetid
```

This convention prevents confusion with the system-generated primary key (`{prefix}_{entityname}id`) and the display name field.

**Relationships:**
```
Format:  {prefix}_{parent}_{child}_{type}
Example: sys_asset_workorder_1N  (one asset to many work orders)
```

**Option Sets (Choice Columns):**
```
Format:  {prefix}_{entityname}_{columnname} (local)
         {prefix}_{name}                    (global/shared)
Example: sys_asset_status (local), sys_prioritylevel (global)
```

### 4.3 Solution Naming Pattern

```
Format:   {ProjectCode}_{Layer}

Examples:
  SYSTRK_Security
  SYSTRK_Core
  SYSTRK_Config
  SYSTRK_Automation
  SYSTRK_UI
```

- `ProjectCode` is uppercase, 3–8 characters, unique per project
- `Layer` is the layer name (the leading underscore is part of the conceptual layer identifier but is not required in the solution name)
- Do not include environment names in solution names — the solution name is constant across environments

**Solution unique names (for API/programmatic use):**
```
Format:   {projectcode}_{layer}  (lowercase)
Examples: systrk_security, systrk_core, systrk_config, systrk_automation, systrk_ui
```

### 4.4 Legacy Prefix Handling

When an existing Power Platform project has a schema prefix that must be retained (e.g., an existing `crm` prefix used across 50 tables), do not rename it. The cost of renaming a schema prefix is extremely high: all column references in flows, apps, and views must be updated, and the rename is not a rename in Dataverse — it is a delete-and-recreate that destroys data.

**Approach for existing prefix retention:**
1. Register the existing prefix as the publisher prefix for the LP-ALM publisher
2. All new components added under LP-ALM use the same prefix (no schema change for end users)
3. Document in the project's `.ai/context.md` that the prefix differs from what a new project would choose
4. The publisher unique name and display name can reflect the project identity without changing the prefix

**Do not create a second publisher** to "start fresh" alongside an existing one in the same environment. Two publishers with different prefixes in the same environment create component ownership ambiguity and complicate future solutions.

### 4.5 Environment Naming and URL Conventions for GCC High

**Environment naming:**
```
Format:   {OrgCode}-{Environment}
Examples:
  AGENCYNAME-Dev
  AGENCYNAME-Test
  AGENCYNAME-Prod
```

**GCC High URLs:**
```
Dev:  https://agencyname-dev.crm.microsoftdynamics.us
Test: https://agencyname-test.crm.microsoftdynamics.us
Prod: https://agencyname.crm.microsoftdynamics.us
```

**Never hardcode these URLs in source control.** They are `_Config` values or Azure DevOps variable group values, not repository content.

---

## 5. Source Control Structure

### 5.1 Recommended Git Repository Layout

```
{project-repo}/
├── .ai/
│   ├── context.md              # AI grounding: project overview, layer summary, key decisions
│   ├── layers.md               # Quick reference: what belongs in each layer
│   ├── schema.md               # Table/column inventory (generated or manually maintained)
│   └── conventions.md          # Naming conventions, prefix, solution names
├── .gitignore                  # Power Platform exclusions (see Section 5.4)
├── README.md                   # Project overview and onboarding pointer
├── LP-ALM.md                   # This methodology document
├── docs/
│   ├── security-role-matrix.md # Role privilege documentation
│   ├── environment-register.md # Environment URLs, types, owners (no secrets)
│   ├── onboarding-checklist.md # New team member onboarding steps
│   └── component-placement-decision-tree.md
├── pipelines/
│   ├── deploy-security.yml     # Deploy _Security layer
│   ├── deploy-core.yml         # Deploy _Core layer
│   ├── deploy-automation.yml   # Deploy _Automation layer
│   ├── deploy-ui.yml           # Deploy _UI layer
│   ├── deploy-all.yml          # Sequential full deployment (Security→Core→Automation→UI)
│   └── pr-validation.yml       # Pull request build validation
└── solutions/
    ├── {ProjectCode}_Security/   # Unpacked _Security solution
    │   └── src/
    │       ├── Entities/
    │       ├── Roles/
    │       ├── FieldSecurityProfiles/
    │       └── Other/
    ├── {ProjectCode}_Core/       # Unpacked _Core solution
    │   └── src/
    │       ├── Entities/
    │       ├── OptionSets/
    │       └── Other/
    ├── {ProjectCode}_Automation/ # Unpacked _Automation solution
    │   └── src/
    │       ├── Workflows/
    │       ├── ConnectionReferences/
    │       └── EnvironmentVariableDefinitions/
    └── {ProjectCode}_UI/         # Unpacked _UI solution
        └── src/
            ├── AppModules/
            ├── CanvasApps/
            ├── SiteMaps/
            └── Dashboards/
```

> **`_Config` has no folder in the repository.** It does not exist in source control at any point.

### 5.2 What Is Committed and What Is Not

**Committed (included in source control):**

| Artifact | Location |
|---|---|
| Unpacked `_Security` solution | `solutions/{ProjectCode}_Security/` |
| Unpacked `_Core` solution | `solutions/{ProjectCode}_Core/` |
| Unpacked `_Automation` solution | `solutions/{ProjectCode}_Automation/` |
| Unpacked `_UI` solution | `solutions/{ProjectCode}_UI/` |
| Pipeline YAML definitions | `pipelines/` |
| AI context documentation | `.ai/` |
| Methodology and role docs | `docs/` |
| `.gitignore` | Root |

**Explicitly excluded from source control:**

| Artifact | Reason |
|---|---|
| `_Config` solution (packed or unpacked) | Contains environment-specific values |
| `*.zip` solution export files | Binary artifacts; solution source is the unpacked form |
| Connection reference values | Environment-specific credential bindings |
| Environment variable values | Environment-specific configuration |
| Service principal secrets | Never in source control |
| `pac auth` profiles | Contain credentials, machine-local |
| `.env` files | May contain secrets or environment-specific values |
| `bin/`, `obj/`, `.vs/` | Build output |

### 5.3 Branch Strategy

LP-ALM uses a trunk-based branch model with environment-aligned protection:

```
main          ← Production-aligned. Protected. All merges via PR. Triggers Prod pipeline on merge.
├── test      ← Test-aligned. Protected. Triggers Test pipeline on push/merge.
└── feature/* ← Developer branches. Short-lived. PR to test or main.
```

**Branch rules:**

| Branch | Trigger | Target Environment | Requires PR | Requires Passing Build |
|---|---|---|---|---|
| `main` | Merge from `test` or hotfix | Prod | Yes | Yes |
| `test` | Merge from `feature/*` | Test | Yes | Yes |
| `feature/*` | Dev work | Dev (manual) | No | No |

**Pipeline triggers by branch:**

```yaml
# deploy-all.yml — triggers on main branch changes
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - solutions/**

# pr-validation.yml — triggers on PR to test or main
pr:
  branches:
    include:
      - test
      - main
```

### 5.4 `.gitignore`

See the `.gitignore` file in this repository root for the complete Power Platform exclusion list.

### 5.5 AI Context Documentation Pattern

The `.ai/` directory provides structured context for GitHub Copilot, Azure AI Foundry, or any LLM-assisted development tool. The purpose is to ground AI suggestions in the project's specific conventions, layer definitions, and schema.

**`.ai/context.md`** — Loaded first by AI tools. Contains:
- Project code and publisher prefix
- Environment list (Dev/Test/Prod URLs, types)
- Layer summary (one sentence per layer)
- Key architectural decisions and their rationale
- "Do not do X" prohibitions (e.g., "Do not add columns to `_UI`")

**`.ai/layers.md`** — Quick decision reference:
- For each layer: one-line purpose + canonical component list
- "If you're unsure where X goes, check this file first"

**`.ai/schema.md`** — Table and column inventory:
- Generated from PAC CLI export or maintained manually
- Helps AI suggest correct column logical names when writing flows or expressions

**`.ai/conventions.md`** — Naming rules:
- Publisher prefix
- Solution names
- Column naming patterns

---

## 5.6 Multi-Developer Workflows

LP-ALM's export → unpack → commit cycle assumes a single developer working in a Dev environment at a given time. Dataverse has no checkout or lock mechanism — whoever exports last captures the current environment state, regardless of who made which change. In multi-developer teams this creates predictable failure modes that must be addressed by team topology and protocol.

### 5.6.1 The Shared Dev Race Condition

Two developers simultaneously modify separate components in a shared Dev environment. Developer A exports immediately after finishing. Developer B exports ten minutes later. Developer B's export captures **both** their changes and Developer A's changes. When Developer B commits, Developer A's work enters source control attributed to Developer B's commit — without review, without a PR, without a diff that makes sense.

The reverse is equally problematic: Developer B exports before Developer A commits, but after Developer A made changes in the environment. Developer B's commit contains Developer A's in-progress, unreviewed work.

**The shared Dev model works for teams of two or three with discipline. It does not scale.**

### 5.6.2 Team-Size Decision Matrix

| Team Size | Recommended Model | Dev Environments |
|---|---|---|
| 1–2 developers | Shared Dev with export protocol | 1 shared Dev |
| 3–5 developers | Shared Dev with layer ownership assignments | 1 shared Dev, strict export serialization |
| 5+ developers | Individual Dev + Integration Dev | 1 per developer + 1 shared Integration Dev |
| Cross-functional teams (Security, Core, UI owned by different people) | Individual Dev + Integration Dev | 1 per developer + 1 shared Integration Dev |

### 5.6.3 Export Serialization Protocol (Shared Dev)

When a single Dev environment is shared, the team must adopt an explicit export protocol to prevent overlapping exports:

1. **Announce before exporting:** Before running `pac solution export`, post a message in the team's coordination channel: `"Exporting _Core — please do not make changes until I commit."`
2. **Export immediately after work is complete.** Do not leave uncommitted changes sitting in Dev while others work around them.
3. **Commit before starting something new.** A developer's changes are not "safe" until they are in source control. Uncommitted state in Dev is invisible to teammates and will be overwritten on the next export.
4. **One layer per export slot.** If you changed both `_Core` and `_Automation`, export and commit `_Core` before starting the `_Automation` export. Mixed-layer exports in the same commit obscure what changed in each layer.

**The coordination overhead of this protocol is a signal.** If the team is spending significant time on export coordination, the shared Dev model has been outgrown. Move to Individual Dev + Integration Dev.

### 5.6.4 Individual Dev + Integration Dev Model

For teams of five or more, or for cross-functional teams where different people own different layers, the correct topology is:

```
Developer A's Individual Dev ──┐
Developer B's Individual Dev ──┼──→ Integration Dev ──→ Test ──→ Prod
Developer C's Individual Dev ──┘
```

**Individual Dev environments:**
- One per developer
- Used as personal scratch environments — the developer owns it completely
- Changes are built here before being formally promoted
- No export to source control happens from individual dev environments
- Individual dev environments do not need to be at full LP-ALM parity at all times

**Integration Dev environment:**
- One shared environment that represents the "current agreed state" of the project
- All five LP-ALM layer solutions are deployed here as unmanaged solutions
- This is the **only** environment from which `pac solution export` is run for source control commits
- Exports from Integration Dev are authoritative
- Maps to the `test` branch (or a dedicated `integration` branch if used)

**Developer workflow:**
```
1. Developer works in their individual environment
2. When feature is complete, developer imports their changed layer solution
   (unmanaged, force-overwrite) into Integration Dev
3. Smoke-test in Integration Dev
4. Export affected layers from Integration Dev
5. Unpack, review diff, commit to feature branch
6. PR to test branch triggers validation pipeline
```

### 5.6.5 Bringing an Individual Dev Environment Up to Date

When starting a new feature, or after a significant period of time, an individual dev environment must be synchronized with the current `main` state. Without this, the developer builds against stale schema and their exports will overwrite newer changes.

**Sync workflow** (also available as `scripts/sync-dev-environment.ps1`):

```powershell
# 1. Authenticate to your individual dev environment
pac auth create `
  --name "MyDev" `
  --kind ServicePrincipal `
  --applicationId <app-id> `
  --clientSecret <secret> `
  --tenant <tenant-id> `
  --cloud UsGovHigh `
  --environment https://yourorg-mydev.crm.microsoftdynamics.us

# 2. Pack each layer from current main (unmanaged)
pac solution pack --zipfile "./sync/SYSTRK_Security.zip" --folder "./solutions/SYSTRK_Security/src" --packagetype Unmanaged
pac solution pack --zipfile "./sync/SYSTRK_Core.zip"     --folder "./solutions/SYSTRK_Core/src"     --packagetype Unmanaged
pac solution pack --zipfile "./sync/SYSTRK_Automation.zip" --folder "./solutions/SYSTRK_Automation/src" --packagetype Unmanaged
pac solution pack --zipfile "./sync/SYSTRK_UI.zip"       --folder "./solutions/SYSTRK_UI/src"       --packagetype Unmanaged

# 3. Import in layer order
pac solution import --path "./sync/SYSTRK_Security.zip"   --force-overwrite true --publish-changes false
pac solution import --path "./sync/SYSTRK_Core.zip"       --force-overwrite true --publish-changes false
# Apply _Config manually for your dev environment here (see Section 6.3)
pac solution import --path "./sync/SYSTRK_Automation.zip" --force-overwrite true --publish-changes false
pac solution import --path "./sync/SYSTRK_UI.zip"         --force-overwrite true --publish-changes true
```

Run this sync at the start of each sprint, after any significant merge to `main`, or any time your individual dev has not been updated in more than a week.

### 5.6.6 Cross-Developer Feature Dependencies

A common scenario: Developer A is building a flow (`_Automation`) that depends on a new column Developer B is adding (`_Core`). Their work is in separate feature branches and separate environments. Developer A cannot build or test their flow until Developer B's column exists.

**Protocol for cross-layer dependencies:**

1. **Schema-first rule.** `_Core` changes must be merged to `test` (or at minimum committed to a feature branch and imported into Integration Dev) before dependent `_Automation` or `_UI` work begins in any environment.

2. **Branch the dependency explicitly.** If Developer B's `feature/new-column` branch contains the needed schema, Developer A can branch from it:
   ```bash
   git checkout feature/new-column
   git checkout -b feature/new-flow
   ```
   Developer A's PR targets `feature/new-column`, not `test`. When `feature/new-column` merges, Developer A rebases and retargets their PR to `test`.

3. **Import the dependency manually.** Developer A imports Developer B's in-progress `_Core` layer solution (from Developer B's individual dev) into their own individual dev. This is a one-way import for local testing — it does not affect source control.

4. **Do not ship them in the same PR.** A PR that contains both `_Core` and `_Automation` changes is harder to review and harder to roll back. If the `_Core` change is independently deployable, merge it first. The `_Automation` PR follows.

### 5.6.7 XML Merge Conflicts in Solution Files

PAC CLI unpacked solutions produce XML files. Git merge conflicts in solution XML are not human-readable and are difficult to resolve manually. The strategies below reduce the frequency and severity of conflicts.

**Prevention:**
- Assign layer ownership where possible. If one developer owns `_Core` for a sprint, only they commit to `solutions/{ProjectCode}_Core/`. This eliminates merge conflicts in that layer entirely for that sprint.
- Keep feature branches short-lived. Long-running feature branches accumulate divergence.
- Export and commit frequently — small diffs are safer than large accumulated diffs.

**When a conflict does occur:**
1. Do not attempt to manually merge conflicting entity XML. The result is unpredictable.
2. Determine which version of the file is correct — this is usually "the one with both changes" but requires understanding what each developer changed.
3. Rebuild the correct state in the environment (typically Integration Dev), then re-export and re-unpack. Let the environment be the merge tool, not git.
4. Accept the re-export output as the resolution. Commit it.

**Canvas apps are the hardest case.** Canvas app source files (produced by `pac canvas unpack`) are complex JSON that does not merge cleanly. For canvas apps specifically, assign a single owner for each app. If two developers must both work on the same canvas app, they should do so serially, not in parallel.

### 5.6.8 `_Config` in Developer Environments

Each individual dev environment needs `_Config` applied once — either on initial setup or when environment variable definitions change. For teams with many individual dev environments, the manual `_Config` protocol (Section 6.3) can become burdensome.

**Lightweight protocol for individual dev environments:**

- Document the set of environment variable values needed for a functional individual dev environment in a **Config Reference Sheet** stored outside source control (shared encrypted document, team wiki, or Azure Key Vault reference). This is not the `_Config` solution file — it is the human-readable values list that a developer uses to configure their environment manually.
- When a developer sets up a new individual dev environment, they apply `_Config` once using the Config Reference Sheet.
- When environment variable definitions change (`_Core` change), the Config Reference Sheet is updated and developers re-apply their `_Config` on next sync.
- **Individual dev `_Config` values may differ from Test/Prod.** This is expected — individual dev environments often point to development-tier external systems, not production systems. The Config Reference Sheet should document which values are environment-tier-specific and what the dev-tier values are.

### 5.6.9 Connection Reference Binding in Developer Environments

Connection references in developer environments present a specific challenge in agencies and programs where service accounts are not available or not permitted.

#### Service Accounts — Best Practice

The best practice for all environments, including individual dev, is to use a **non-interactive service account** bound to connection references:

- A licensed M365/Power Platform service account (a user account, not a service principal) with a non-expiring password or managed credential
- The account is assigned the `{ProjectCode} - Automation Service` security role
- The connection reference in the environment is bound to a connection created under this service account
- No developer's personal credentials appear in any connection

This approach ensures flows work even when individual team members leave or rotate credentials, and satisfies audit requirements that connections are not personally attributable.

#### When Service Accounts Are Not Available

In many DoD agencies and classified programs, provisioning a service account for development purposes is restricted or prohibited by policy. Common constraints include:

- No shared credentials permitted — every account must be attributed to an individual
- CAC/PIV-only authentication — service accounts without hardware tokens cannot be provisioned
- Zero standing access policies — no persistent service accounts; all access is just-in-time
- Account lifecycle policies that treat shared accounts as a compliance violation

When service accounts are not available, the following approach applies:

**Individual dev and Integration Dev environments:**
- Developers bind connection references to their own personal credentials in dev environments
- This is acceptable for development environments — it is **not** acceptable in Test, UAT, or Prod
- Document explicitly in the environment register which connections are personally bound
- Flows may break when that developer rotates credentials or departs — this is a known limitation of personal bindings and is acceptable risk in a dev-only environment
- When the developer leaves the project, their personal connections must be re-bound by another team member before the next Integration Dev export

**Test and above:**
- In environments where service accounts are prohibited but functional connections are required, the team must escalate to the agency's Identity and Access Management (IAM) team and document the following:
  - A formal request for a non-interactive service account (or equivalent managed identity) for the specific purpose of Power Platform connection references
  - The security controls applied to that account (MFA, conditional access, role-limited to the `{ProjectCode} - Automation Service` role)
  - The approval authority granting exception or standard provisioning
- This is not an LP-ALM limitation — it is an agency IAM policy question. LP-ALM documents the technical requirement; the project team resolves it through the agency's standard account provisioning process.

**Pipeline service principals:**
- The `prvWriteRole` requirement (System Administrator for the `_Security` pipeline job) is separate from connection references
- Pipeline service principals authenticate via client secret or certificate — this is typically less restricted than shared user accounts because the credential is managed in Azure Key Vault, not by a human
- If even service principals are restricted (rare but possible in some classified programs), the pipeline must be redesigned to use interactive authentication with just-in-time approval — consult the agency's DevSecOps team for approved alternatives

**Summary by environment tier:**

| Tier | Service Account Available | Service Account Prohibited |
|---|---|---|
| Individual Dev | Use service account (best practice) | Personal credentials acceptable — documented limitation |
| Integration Dev | Use service account | Personal credentials acceptable with documented owner |
| Test / SIT | Use service account — required | Escalate to IAM; do not use personal credentials |
| UAT | Use service account — required | Escalate to IAM; do not use personal credentials |
| Prod | Use service account — required | Cannot proceed without IAM-approved non-personal credential |

---

### 6.1 Export → Unpack → Commit Cycle

The standard LP-ALM developer cycle for each layer:

```
1. Make changes in Dev environment (unmanaged)
2. Export solution from Dev
3. Unpack solution to source directory
4. Review diff (git diff)
5. Commit and push
6. PR to test branch triggers validation pipeline
7. Merge to test triggers Test deployment pipeline
8. Merge to main triggers Prod deployment pipeline
```

### 6.2 PAC CLI Commands

#### Authentication

```bash
# Commercial
pac auth create \
  --name "Dev" \
  --kind ServicePrincipal \
  --applicationId <app-id> \
  --clientSecret <secret> \
  --tenant <tenant-id> \
  --environment https://yourorg.crm.dynamics.com

# GCC High
pac auth create \
  --name "Dev-GCCHigh" \
  --kind ServicePrincipal \
  --applicationId <app-id> \
  --clientSecret <secret> \
  --tenant <tenant-id> \
  --cloud UsGovHigh \
  --environment https://yourorg.crm.microsoftdynamics.us
```

#### Export and Unpack (per layer)

```bash
# Export unmanaged solution from Dev
pac solution export \
  --name "SYSTRK_Security" \
  --path "./exports/SYSTRK_Security.zip" \
  --managed false \
  --overwrite true

# Unpack to source directory
pac solution unpack \
  --zipfile "./exports/SYSTRK_Security.zip" \
  --folder "./solutions/SYSTRK_Security/src" \
  --packagetype Unmanaged \
  --allowDelete true \
  --allowWrite true \
  --clobber true
```

Repeat for each layer (`SYSTRK_Core`, `SYSTRK_Automation`, `SYSTRK_UI`).

#### Pack and Import (for pipeline or local testing)

```bash
# Pack managed solution (for Test/Prod deploy)
pac solution pack \
  --zipfile "./output/SYSTRK_Security_managed.zip" \
  --folder "./solutions/SYSTRK_Security/src" \
  --packagetype Managed

# Pack unmanaged solution (for Dev deploy)
pac solution pack \
  --zipfile "./output/SYSTRK_Security_unmanaged.zip" \
  --folder "./solutions/SYSTRK_Security/src" \
  --packagetype Unmanaged

# Import to target environment
pac solution import \
  --path "./output/SYSTRK_Security_managed.zip" \
  --activate-plugins true \
  --force-overwrite true \
  --publish-changes true \
  --skip-dependency-check false
```

#### Version Bumping

LP-ALM uses semantic versioning for solutions. The version is set at pack time:

```bash
# Pack with explicit version
pac solution pack \
  --zipfile "./output/SYSTRK_Security_managed.zip" \
  --folder "./solutions/SYSTRK_Security/src" \
  --packagetype Managed \
  --solutionversion "1.4.0.0"
```

**Versioning convention:**
```
{Major}.{Minor}.{Patch}.{Build}
 1      .4      .0      .0

Major: Breaking schema changes (column deletes, table renames — rare and controlled)
Minor: New functionality (new tables, new flows, new app features)
Patch: Bug fixes and non-breaking updates
Build: Pipeline build number (auto-incremented by ADO, injected at pipeline time)
```

### 6.3 Handling the `_Config` Layer

`_Config` is exported only — never committed, never pipeline-imported.

```bash
# Export _Config from reference environment (Dev)
pac solution export \
  --name "SYSTRK_Config" \
  --path "./SYSTRK_Config_$(Get-Date -Format 'yyyyMMdd').zip" \
  --managed false \
  --overwrite true

# DO NOT unpack to solutions/ directory
# DO NOT commit the zip or unpacked files
# Store securely (e.g., encrypted file share, key vault reference)
```

**Manual import to target environment:**
```bash
pac solution import \
  --path "./SYSTRK_Config_20260512.zip" \
  --force-overwrite true \
  --publish-changes true
```

The person performing the import must have the environment-specific values already prepared. The zip file should not be stored in version control — it should be treated as a configuration artifact, not a code artifact.

### 6.4 Bulk Export Script (All Layers)

```powershell
# export-all-layers.ps1
param(
    [string]$ProjectCode = "SYSTRK",
    [string]$ExportPath = "./exports"
)

$layers = @("Security", "Core", "Automation", "UI")
# Note: _Config is deliberately excluded

foreach ($layer in $layers) {
    $solutionName = "${ProjectCode}_${layer}"
    $outputFile = "$ExportPath/${solutionName}.zip"

    Write-Host "Exporting $solutionName..."
    pac solution export `
        --name $solutionName `
        --path $outputFile `
        --managed false `
        --overwrite true

    Write-Host "Unpacking $solutionName..."
    pac solution unpack `
        --zipfile $outputFile `
        --folder "./solutions/${solutionName}/src" `
        --packagetype Unmanaged `
        --allowDelete true `
        --allowWrite true `
        --clobber true

    Write-Host "$solutionName complete."
}

Write-Host "All layers exported and unpacked. _Config was intentionally skipped."
```

---

## 7. Azure DevOps Pipeline Architecture

### 7.1 Pipeline Architecture Decision: Per-Layer vs. Single Pipeline

**Recommendation: Per-layer pipelines with a single orchestration pipeline.**

| Approach | Pros | Cons |
|---|---|---|
| Single pipeline, all layers as stages | Simple to trigger, one YAML file | Cannot deploy a single layer independently; full pipeline runs for a one-layer change |
| Per-layer pipelines only | Maximum flexibility, each layer triggers independently | No coordination for full deployments; manual trigger sequencing |
| **Per-layer + orchestration (recommended)** | Independent layer deploy + coordinated full deploy | More YAML files, but separates concerns cleanly |

The orchestration pipeline (`deploy-all.yml`) calls the layer pipelines in sequence with dependency gates. Individual layer pipelines (`deploy-security.yml`, `deploy-core.yml`, etc.) can be triggered independently for hotfixes.

### 7.2 Stage Sequence and Dependency Gates

```
deploy-all.yml pipeline:

Stage: Deploy_Test
  ├── Job: Deploy_Security_Test
  ├── Job: Deploy_Core_Test         (dependsOn: Deploy_Security_Test)
  │         [_Config must be manually applied before this pipeline runs if env vars are new]
  ├── Job: Deploy_Automation_Test   (dependsOn: Deploy_Core_Test)
  └── Job: Deploy_UI_Test           (dependsOn: Deploy_Automation_Test)

Stage: Manual_Approval             (environment approval gate — requires human sign-off)

Stage: Deploy_Prod
  ├── Job: Deploy_Security_Prod
  ├── Job: Deploy_Core_Prod         (dependsOn: Deploy_Security_Prod)
  ├── Job: Deploy_Automation_Prod   (dependsOn: Deploy_Core_Prod)
  └── Job: Deploy_UI_Prod           (dependsOn: Deploy_Automation_Prod)
```

### 7.3 Required Pipeline Variables and Variable Groups

**Variable Group: `{ProjectCode}-Common`** (applies to all environments)

| Variable | Example Value | Secret? |
|---|---|---|
| `ProjectCode` | `SYSTRK` | No |
| `PublisherPrefix` | `sys` | No |
| `SolutionVersion.Major` | `1` | No |
| `SolutionVersion.Minor` | `4` | No |

**Variable Group: `{ProjectCode}-Test`** (Test environment specific)

| Variable | Example Value | Secret? |
|---|---|---|
| `Test.EnvironmentUrl` | `https://yourorg-test.crm.microsoftdynamics.us` | No |
| `Test.ApplicationId` | `<app-id>` | No |
| `Test.TenantId` | `<tenant-id>` | No |
| `Test.ClientSecret` | `<secret>` | **Yes** |
| `Test.ServiceConnectionName` | `SYSTRK-Test-ServicePrincipal` | No |

**Variable Group: `{ProjectCode}-Prod`** (Prod environment specific)

| Variable | Example Value | Secret? |
|---|---|---|
| `Prod.EnvironmentUrl` | `https://yourorg.crm.microsoftdynamics.us` | No |
| `Prod.ApplicationId` | `<app-id>` | No |
| `Prod.TenantId` | `<tenant-id>` | No |
| `Prod.ClientSecret` | `<secret>` | **Yes** |
| `Prod.ServiceConnectionName` | `SYSTRK-Prod-ServicePrincipal` | No |

**What does NOT go in variable groups:**
- `_Config` solution values (they are not pipeline values — they are manual environment configuration)
- Connection reference values (bound in the environment, not passed via pipeline)
- Environment variable current values (these are `_Config`, not pipeline variables)

### 7.4 Service Connection Setup for GCC High

1. In Azure DevOps, navigate to **Project Settings → Service Connections**
2. Create a new **Power Platform** service connection (or Generic if Power Platform type is unavailable)
3. For GCC High, the server URL must be `https://yourorg.crm.microsoftdynamics.us`
4. Use **Service Principal / Client Secret** authentication (not interactive)
5. The App Registration must be in **Azure Government** (`portal.azure.us`), not commercial Azure

Alternatively, use inline PAC CLI authentication via task inputs:

```yaml
- task: PowerPlatformToolInstaller@2
  displayName: 'Install Power Platform Tools'
  inputs:
    DefaultVersion: true

- task: PowerPlatformSetConnectionVariables@2
  displayName: 'Set Connection Variables'
  inputs:
    authenticationType: 'PowerPlatformSPN'
    PowerPlatformSPN: '$(Test.ServiceConnectionName)'
```

### 7.5 Example YAML: Full Deploy Pipeline

See [pipelines/deploy-all.yml](pipelines/deploy-all.yml) in this repository for the complete annotated pipeline. See also [pipelines/deploy-security.yml](pipelines/deploy-security.yml), [pipelines/deploy-core.yml](pipelines/deploy-core.yml), [pipelines/deploy-automation.yml](pipelines/deploy-automation.yml), and [pipelines/deploy-ui.yml](pipelines/deploy-ui.yml) for individual layer pipelines.

Key structural elements:

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - solutions/**
      - pipelines/**

parameters:
  - name: targetEnvironment
    displayName: 'Target Environment'
    type: string
    default: 'test'
    values:
      - test
      - prod

variables:
  - group: SYSTRK-Common
  - ${{ if eq(parameters.targetEnvironment, 'test') }}:
    - group: SYSTRK-Test
  - ${{ if eq(parameters.targetEnvironment, 'prod') }}:
    - group: SYSTRK-Prod
  - name: BuildNumber
    value: $(Build.BuildNumber)
```

### 7.6 Pull Request Validation Pipeline

The PR validation pipeline ([pipelines/pr-validation.yml](pipelines/pr-validation.yml)) runs on every PR to `test` or `main`. It does not deploy — it validates that each solution can be packed without error.

```yaml
trigger: none  # No direct trigger; only runs on PRs

pr:
  branches:
    include:
      - test
      - main

steps:
  - task: PowerPlatformToolInstaller@2
    displayName: 'Install PAC CLI'

  - script: |
      pac solution pack \
        --zipfile "$(Build.ArtifactStagingDirectory)/SYSTRK_Security_managed.zip" \
        --folder "$(Build.SourcesDirectory)/solutions/SYSTRK_Security/src" \
        --packagetype Managed
    displayName: 'Validate Pack: Security'

  - script: |
      pac solution pack \
        --zipfile "$(Build.ArtifactStagingDirectory)/SYSTRK_Core_managed.zip" \
        --folder "$(Build.SourcesDirectory)/solutions/SYSTRK_Core/src" \
        --packagetype Managed
    displayName: 'Validate Pack: Core'

  - script: |
      pac solution pack \
        --zipfile "$(Build.ArtifactStagingDirectory)/SYSTRK_Automation_managed.zip" \
        --folder "$(Build.SourcesDirectory)/solutions/SYSTRK_Automation/src" \
        --packagetype Managed
    displayName: 'Validate Pack: Automation'

  - script: |
      pac solution pack \
        --zipfile "$(Build.ArtifactStagingDirectory)/SYSTRK_UI_managed.zip" \
        --folder "$(Build.SourcesDirectory)/solutions/SYSTRK_UI/src" \
        --packagetype Managed
    displayName: 'Validate Pack: UI'

  # Note: _Config is never validated in pipeline
```

---

## 8. Security Role Design Guidance

### 8.1 Role Naming Conventions

```
Format:   {ProjectCode} - {PersonaOrFunction}

Examples:
  SYSTRK - Administrator
  SYSTRK - Contributor
  SYSTRK - Read Only
  SYSTRK - Support
  SYSTRK - Automation Service
```

- Use a dash separator between project code and role name
- Role names should describe the function, not the technology (not "SYSTRK - Table Editor")
- Do not include environment names in role names — roles are environment-agnostic
- Do not prefix with publisher prefix — security role names are display names, not schema names

### 8.2 Privilege Matrix Structure

Security roles are defined at three levels:

1. **Table level:** Create, Read, Update, Delete, Append, Append To, Assign, Share — per table, per access level (None, User, Business Unit, Parent Business Unit, Organization)
2. **Field level:** Field Security Profiles (separate component, not embedded in the role itself)
3. **Miscellaneous privileges:** System-level capabilities (e.g., `prvWriteRole`, `prvExportToExcel`, `prvGoOffline`)

**Privilege Matrix Template:**

| Table | Admin | Contributor | Read Only | Support | Automation Svc |
|---|---|---|---|---|---|
| `sys_asset` | Org CRUDAAS | BU CRUD+AA | BU R | BU R+U | Org CRUD+AA |
| `sys_workorder` | Org CRUDAAS | BU CRUD+AA | BU R | BU R+U | Org CRUD+AA |
| `sys_location` | Org CRUDAAS | BU R | BU R | BU R | Org R |

**Key:** C=Create, R=Read, U=Update, D=Delete, A=Append, AS=Append To, Asn=Assign, S=Share  
**Access Levels:** None, U=User, BU=Business Unit, PBU=Parent BU, Org=Organization

See [docs/security-role-matrix-template.md](docs/security-role-matrix-template.md) for the full template.

### 8.3 Append and Append To — Explicit Setting Required

**Append** and **Append To** are the most commonly missed privileges in Power Platform security role design. They control relationship traversal:

- **Append:** Allows a record of table A to be associated with a record of table B (the "from" side of a relationship)
- **Append To:** Allows records of table B to be appended to table A (the "to" side)

**Both must be explicitly set for every relationship that a role needs to traverse.** Failing to set either one produces cryptic errors where users can see records but cannot associate them, or where flows fail with access denied on relationship operations.

**Rule:** For every lookup column a role can read, verify:
1. The role has **Append** on the table *containing* the lookup column
2. The role has **Append To** on the table *being looked up*

### 8.4 Team Configuration

LP-ALM uses Owner Teams (not Access Teams) for group-based access assignment.

**Team Type:** Owner Team  
**Access Level on Roles:** Direct User (Basic) — team members inherit privileges at the User level through team membership  
**Team Privileges:** Assigned to the team via security role assignment; team members acquire access through team membership

**Why Direct User (Basic) access level:**
- Prevents a team role from granting Organization-wide access to all team members by default
- Maintains the principle that access scope is bounded by the team's assigned records, not the entire Business Unit
- Aligned with least-privilege: users get access to records through team membership, not blanket BU-wide access

**Owner Team creation is environment data, not solution data.** Owner teams are created after solution import by an administrator — they cannot be solution-deployed. The team configuration requirements are documented in `_Security` layer documentation, but the actual team records must be created manually in each environment.

### 8.5 `prvWriteRole` Requirement for Pipeline Service Principals

The `prvWriteRole` privilege — required to deploy security roles — is only available to the built-in **System Administrator** role. It cannot be granted to a custom security role.

**Impact:** The service principal used for the `_Security` layer pipeline job must have the **System Administrator built-in role** in the target environment.

**Implementation options:**

1. **Dedicated SP for `_Security`:** Use a separate service principal for the Security layer with System Administrator; use a minimum-privilege SP for remaining layers
2. **Single SP with System Administrator:** Accept System Administrator for one SP and compensate with pipeline access controls (only the pipeline can invoke this SP, not individual developers)
3. **Document the exception:** Either way, the System Administrator assignment must be documented in the security plan as a justified exception, not an oversight

**Do not grant System Administrator to a service principal without documenting this in the security plan.**

### 8.6 Least-Privilege Role Design for Common Personas

#### `{ProjectCode} - Administrator`
Full access for system administrators maintaining the platform.
- All custom tables: Organization-level CRUDAAS
- All miscellaneous project-relevant privileges
- Field security: access to all field security profiles

#### `{ProjectCode} - Contributor`
Standard user who creates and manages their own records.
- Own tables: BU-level CRUD + Append + Append To
- Related tables (read-only context): BU-level Read only
- No Delete on high-value records (configure per table)
- Field security: standard profile (no restricted fields)

#### `{ProjectCode} - Read Only`
View records without modification.
- All custom tables: BU-level Read only
- No Create, Update, Delete, Append, Append To
- Field security: standard profile (restricted fields hidden or read-only)

#### `{ProjectCode} - Support`
View and update records for troubleshooting; no create or delete.
- All custom tables: BU-level Read + Update
- No Create, Delete
- Append + Append To for relationships they may need to navigate
- Field security: support profile (may include some restricted fields read-only)

#### `{ProjectCode} - Automation Service`
Service account role for Power Automate flows and integrations.
- All custom tables: Organization-level CRUD + Append + Append To
- No Assign or Share (flows don't need record reassignment unless explicitly designed)
- Miscellaneous: only privileges required by specific flows (explicitly listed)
- This role is assigned to the service account used by connection references

---

## 9. Environment Strategy

### 9.1 Recommended Environment Topology

**Minimum viable topology (three environments):**
```
Dev → Test → Prod
```

**Extended topology (four environments, recommended for regulated):**
```
Dev → SIT → UAT → Prod
```

**Multi-developer topology (recommended for teams of 5+):**
```
Individual Dev (per developer) → Integration Dev → Test → Prod
```

**Enterprise topology:**
```
Individual Dev (per developer) → Integration Dev → SIT → UAT → Prod
```

For GCC High deployments, a commercial sandbox environment is often maintained alongside the GCC High topology for development tooling access (e.g., Copilot Studio features not yet available in GCC High), with the GCC High Integration Dev as the canonical source for exports.

**Choosing a topology:**

| Condition | Recommended Topology |
|---|---|
| Solo developer or 2-person team | Shared Dev → Test → Prod |
| 3–5 developers, same functional area | Shared Dev → Test → Prod with export protocol |
| 5+ developers | Individual Dev + Integration Dev → Test → Prod |
| Cross-functional team (Security, Core, UI owned separately) | Individual Dev + Integration Dev → Test → Prod |
| Regulated/GCC High, any team size | Individual Dev + Integration Dev → SIT → UAT → Prod |

See Section 5.6 for the full multi-developer workflow, export serialization protocol, and Integration Dev operating procedures.

### 9.2 What Is Deployed to Each Environment

| Layer | Dev | SIT/Test | UAT | Prod |
|---|---|---|---|---|
| `_Security` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |
| `_Core` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |
| `_Config` | Unmanaged, **manual** | Unmanaged, **manual** | Unmanaged, **manual** | Unmanaged, **manual** |
| `_Automation` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |
| `_UI` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |

**Key observations:**
- `_Config` is always unmanaged and always manual — in every environment without exception
- Pipeline automation applies only to Test/Prod (and SIT/UAT in extended topology)
- Dev environments receive unmanaged solutions so developers can iterate without pipeline overhead

### 9.3 Data Residency and Sovereignty for GCC High

GCC High environments are physically isolated in Azure Government regions (USGov Virginia, USGov Texas). Data at rest and in transit does not cross into commercial Azure regions.

**Relevant constraints for LP-ALM:**
- Development environments for GCC High projects may be in commercial (for developer tooling access), but Test and Prod must be in GCC High
- Any external integration (API, webhook, connector) called from GCC High flows must also reside in a FedRAMP-authorized boundary or be explicitly authorized for data egress
- Custom connectors used by `_Automation` must point to FedRAMP-authorized endpoints
- Microsoft 365 connectors (SharePoint, Teams, Exchange) used in flows must reference M365 GCC High endpoints, not commercial

**Data flow documentation requirement:** For ATO packages, document the data flow from GCC High Power Platform to every external system called by `_Automation` layer flows. Undocumented external data flows are a common ATO finding.

### 9.4 Managed vs. Unmanaged Solution Rules Per Environment Tier

| Rule | Dev | Test/SIT | UAT | Prod |
|---|---|---|---|---|
| Solution type | Unmanaged | Managed | Managed | Managed |
| Can developers make ad-hoc changes? | Yes | No (managed lock) | No (managed lock) | No (managed lock) |
| Changes tracked in pipeline? | No (Dev is sandbox) | Yes | Yes | Yes |
| Rollback mechanism | Re-import previous version | Re-import managed solution from pipeline artifact | Same | Same |
| `_Config` managed? | Never | Never | Never | Never |

**Never deploy a managed solution to Dev.** A managed solution in Dev prevents iteration and will block future unmanaged imports of the same solution name.

---

## 10. Onboarding Guide for New Teams

### 10.1 Starting a New Project with LP-ALM from Scratch

#### Phase 1: Setup (before any development)

1. **Create the publisher** in the Dev environment
   - Display Name: `{Project Name}`
   - Unique Name: `{projectname}` (lowercase, no spaces)
   - Prefix: `{2–5 char lowercase prefix}`

2. **Create the five solution shells** in Dev (empty, linked to publisher)
   - `{ProjectCode}_Security`
   - `{ProjectCode}_Core`
   - `{ProjectCode}_Config`
   - `{ProjectCode}_Automation`
   - `{ProjectCode}_UI`

3. **Initialize the repository**
   - Clone or fork the LP-ALM reference repository
   - Update `README.md`, `.ai/context.md`, `.ai/layers.md`, `.ai/conventions.md`
   - Update `pipelines/*.yml` with project-specific variable group names and solution names

4. **Register the service principal**
   - GCC High: App registration in Azure Government (`portal.azure.us`)
   - Commercial: App registration in Azure commercial (`portal.azure.com`)
   - Create application user in Dev, Test, and Prod environments
   - Assign System Administrator role in all environments

5. **Create Azure DevOps variable groups**
   - `{ProjectCode}-Common`
   - `{ProjectCode}-Test`
   - `{ProjectCode}-Prod`
   - Populate secrets into the Secret-flagged variables

6. **Configure pipeline service connections** in Azure DevOps (Project Settings → Service Connections)

#### Phase 2: First Development Cycle

1. Build `_Security` layer first:
   - Create security roles in Dev (add to unmanaged `_Security` solution)
   - Define field security profiles
   - Export, unpack, commit

2. Build `_Core` layer:
   - Create all tables, columns, relationships in Dev (add to unmanaged `_Core` solution)
   - Build views and forms
   - Export, unpack, commit

3. Configure `_Config` for each environment:
   - Set environment variable values manually in each environment
   - **Do not commit anything**

4. Build `_Automation`:
   - Create flows in Dev, added to the `_Automation` solution
   - Configure connection references using service accounts
   - Export, unpack, commit

5. Build `_UI`:
   - Create apps, site maps, dashboards in Dev, added to `_UI` solution
   - Add no new columns — all columns must already exist in `_Core`
   - Export, unpack, commit

6. Run the first pipeline to Test:
   - `_Security` → `_Core` → *(verify `_Config` manually applied)* → `_Automation` → `_UI`

#### Phase 3: Steady-State Development

- All changes go through the export → unpack → PR → pipeline cycle
- `_Config` changes are documented in the environment configuration register (not source control)
- Version numbers are bumped per the semantic versioning convention
- PRs require at least one reviewer before merge to `test` or `main`

### 10.2 Common Mistakes and How to Avoid Them

| Mistake | Symptom | Prevention |
|---|---|---|
| Adding a column in `_UI` | Schema contamination; `_UI` managed imports fail in upper environments | Run solution checker before export; review `git diff` for unexpected `Entities/` content inside `_UI` solution folder |
| Committing `_Config` | Secrets or environment-specific values in source control | `.gitignore` excludes `_Config`; add a pre-commit hook that checks for `Config` solution directories |
| Personal credentials in connection references | Flows break when user's account is rotated or deprovisioned | Policy: only service accounts in connection references; enforce in pipeline connection validation step |
| Deploying `_Automation` before `_Config` | Flows fail on import or activation due to missing env var values | Pipeline gate: document manual `_Config` step and add a pre-stage gate confirmation |
| Wrong publisher prefix | Schema naming inconsistency; solution check failures | Set publisher once at project start; document in `.ai/conventions.md`; do not change |
| App registration in wrong tenant (GCC High) | PAC CLI auth fails; pipeline cannot connect to GCC High environment | Use `portal.azure.us` for GCC High app registrations; verify `--cloud UsGovHigh` flag in all PAC auth commands |
| Deploying managed solution to Dev | Blocks future unmanaged imports of the same solution | Dev always gets unmanaged; enforced by pipeline parameter that maps environment to package type |
| Missing Append / Append To | Users cannot associate records; flows get access denied on relationship operations | Use privilege matrix template; explicitly audit every lookup relationship against the Append/Append To columns |
| Skipping `_Security` deploy after schema changes | New table exists in environment without security role coverage | Pipeline dependency gates prevent `_Core` from deploying without successful `_Security` gate |

### 10.3 Decision Checklist Before First Pipeline Run

- [ ] `_Security` layer exported, unpacked, and committed
- [ ] `_Core` layer exported, unpacked, and committed
- [ ] `_Automation` layer exported, unpacked, and committed
- [ ] `_UI` layer exported, unpacked, and committed
- [ ] `_Config` manually applied to target environment (confirmed — NOT committed)
- [ ] Service principal application user exists in target environment
- [ ] System Administrator role assigned to service principal in target environment
- [ ] Azure DevOps variable groups created and populated
- [ ] Pipeline service connections configured and connection test passing
- [ ] Connection references in target environment bound to service account connections (not personal)
- [ ] Environment URL in pipeline variables matches target (`.crm.microsoftdynamics.us` for GCC High)
- [ ] No schema components found in `_UI` solution (verified with solution checker or diff review)
- [ ] Solution versions set correctly in pipeline variables
- [ ] PR validation pipeline passed on current branch

### 10.4 Migrating an Existing Monolithic Solution to LP-ALM

Migrating a monolithic solution is a structured decomposition process.

**Step 1: Inventory**

Export the monolithic solution and unpack it. Catalog all components by layer:
- Tables, columns, views, forms → `_Core`
- Security roles, field security profiles → `_Security`
- Flows, connection references → `_Automation`
- Apps, site maps, dashboards → `_UI`
- Environment variable definitions → `_Core`
- Environment variable values → `_Config`

**Step 2: Create the five solution shells**

Create empty solutions for each layer in the Dev environment, linked to the same publisher as the monolithic solution.

**Step 3: Move components — Security first**

In Dev:
1. Add all security roles and field security profiles to `_Security` solution
2. Remove them from the monolithic solution
3. Verify the roles still work (components are the same — only solution association changes)

**Step 4: Move schema to `_Core`**

Add all tables, columns, relationships, views, and forms to `_Core`. Remove from monolith.

**Step 5: Move flows to `_Automation`**

Add all flows and connection references to `_Automation`. Remove from monolith.

**Step 6: Move apps to `_UI`**

Add all model-driven apps, canvas apps, site maps, and dashboards to `_UI`. Remove from monolith.

**Step 7: Identify `_Config` values**

Identify all environment variable current values and document them outside source control in the environment configuration register.

**Step 8: Export, unpack, commit all layers**

Run the bulk export script. Review the diff carefully. Commit.

**Step 9: Plan the cutover**

The monolithic solution must be deleted from Test and Prod before the LP-ALM layers are deployed (to avoid component ownership conflicts between managed solutions). Plan a maintenance window. Cutover sequence:

1. Export all data (backup)
2. Remove monolithic managed solution from Test/Prod (deletion propagates)
3. Deploy `_Security` → `_Core` → *(manual `_Config`)* → `_Automation` → `_UI`
4. Validate and smoke test all functionality
5. Document go-live in change management record

**Step 10: Archive the monolith**

Keep the monolithic solution export for rollback reference, but remove it from source control.

---

## 11. Methodology Positioning

### 11.1 Presenting LP-ALM to Audiences

#### To Executives

> "LP-ALM is an approach to building Power Platform solutions that separates your data structure, security, business logic, and user interface into independently deployable units. This gives your organization the ability to update a security policy without touching the application, or update a dashboard without risking a database change. For regulated environments, it also ensures that access controls are always in place before data structures exist — which is a requirement under NIST 800-53 and CMMC."

Key executive talking points:
- Reduced deployment risk (smaller blast radius per change)
- Audit-ready architecture from day one
- Independent team ownership reduces bottlenecks
- Supports compliance frameworks without additional tooling overhead

#### To Technical Teams

> "LP-ALM is a five-layer decomposition pattern for Power Platform solutions. Security roles deploy first — before schema — as a structural control. Config is excluded from source control by design. All upper-environment deployments are managed solutions. Each layer has its own pipeline job, its own source control path, and its own rollback unit. If you break a flow, you redeploy `_Automation`. If you break a table, you redeploy `_Core`. You never redeploy the whole stack for a one-component change."

Technical talking points:
- Pipeline architecture (per-layer jobs, ADO variable groups, dependency gates)
- PAC CLI export/unpack/commit cycle
- Managed solution enforcement and rollback
- GCC High service principal setup and cloud flag
- Branch strategy and PR gates

#### To Security Officers

> "LP-ALM implements a security-first deployment model aligned with NIST 800-53 AC-2, AC-3, CM-2, CM-3, and SA-3. Security roles are the first deployment action in every environment — no data structure can exist without a corresponding access control structure. Environment-specific configuration values are excluded from source control, eliminating a class of secrets-exposure risk. All production changes go through a pipeline with mandatory PR review. The architecture supports GCC High FedRAMP requirements including service principal-only authentication and sovereign cloud endpoint enforcement."

Security talking points:
- NIST control mapping (see Section 3.4)
- Zero-secrets-in-repo guarantee
- Managed solution change control
- Service principal authentication model
- FedRAMP / GCC High compliance posture and data residency

### 11.2 Differentiation from Microsoft's Default ALM Guidance

Microsoft's Power Platform ALM documentation recommends using solutions for deployment and source control. It acknowledges the possibility of multiple solutions per project but stops short of defining a structured layer model.

LP-ALM extends Microsoft's guidance in three meaningful ways:

1. **Security-first deployment order is a structural control, not a convention.** Microsoft's documentation does not prescribe deployment sequence for security roles. LP-ALM makes the sequence non-negotiable and expresses it as a compliance control with NIST mapping.

2. **Config exclusion is an explicit protocol, not a default.** Microsoft's ALM documentation includes environment variables as a standard solution component. LP-ALM explicitly excludes `_Config` from source control and pipelines, creating a zero-secrets-in-repo architecture not described in default guidance.

3. **GCC High sovereign cloud specificity.** Microsoft's general Power Platform ALM guidance is written for commercial environments. LP-ALM explicitly addresses `.crm.microsoftdynamics.us` endpoints, Azure Government app registrations, and service principal requirements specific to GCC High.

LP-ALM is compatible with Microsoft's Power Platform CoE Starter Kit and does not conflict with Microsoft's ALM Accelerator — it can be adopted alongside both.

### 11.3 When LP-ALM Is Overkill

LP-ALM is not appropriate for:
- **Single-environment solutions** — no deployment pipeline means the layer architecture provides no deployment benefit
- **Prototype and proof-of-concept work** — five solutions, pipelines, and service principals is excessive for short-lived work
- **Citizen developer projects** — low-code makers without ALM tooling should use the simplest solution structure that works
- **Single-person projects without change control requirements** — per-layer pipeline overhead is unnecessary
- **Solutions that will never go to a regulated environment** — compliance posture features add complexity with no return

**Reasonable threshold for adoption:** LP-ALM is appropriate when the project has two or more of the following: multiple environments, a team of two or more makers, a compliance requirement, or an expectation of 12+ months of active development.

### 11.4 Recommended Deliverables for Consulting Engagements

| Deliverable | Description | Primary Owner |
|---|---|---|
| LP-ALM Methodology Document | This document, customized with project code, prefix, and environment details | Architect |
| Publisher and Solution Setup | Five solutions created in Dev, publisher configured, prefix documented | Architect |
| Source Control Repository | Initialized repo with `.gitignore`, `.ai/` structure, `pipelines/`, `docs/` | Architect |
| Pipeline YAML Files | All six pipeline files (5 deploy + 1 PR validation) | Architect |
| Security Role Matrix | Table of roles, tables, and privilege levels per persona | Security Lead |
| Environment Register | Environment URLs, types, access contacts (no secrets) | Architect |
| ADO Variable Groups | Created and documented; secrets populated by customer | Architect + Customer |
| Service Principal Setup Guide | App registration steps, application user setup, role assignment | Architect |
| Onboarding Runbook | Steps for a new developer to get productive in the project | Architect |
| Config Management Protocol | Written procedure for `_Config` handling (document in deliverable set, not source control) | Architect |

**Estimated engagement scope:** 8–16 hours for greenfield setup; 24–40 hours for monolithic migration depending on solution complexity.

---

## 12. Platform Prerequisites & Complementary Guidance

### 12.1 What LP-ALM Governs (and What It Does Not)

LP-ALM governs what is **inside a solution artifact** and how that artifact moves between environments. It does not govern the platform layer — the tenant-level, environment-level, and infrastructure configuration that must exist before LP-ALM pipelines can run successfully.

This boundary is intentional. Platform governance responsibilities — DLP policies, environment provisioning, Managed Environments configuration, monitoring infrastructure, BCDR — are typically owned by a central Power Platform admin team and are documented in Microsoft's own reference frameworks. Reproducing that guidance here would create a maintenance burden and risk drift from Microsoft's authoritative documentation.

LP-ALM is **composable with** Microsoft's platform governance frameworks. It sits at the solution layer; the frameworks below sit at the platform layer.

---

### 12.2 Platform Prerequisites

The following must be true in each target environment before LP-ALM pipelines will operate correctly. These are platform admin responsibilities, not LP-ALM responsibilities.

| Prerequisite | Why LP-ALM Depends On It |
|---|---|
| Dataverse provisioned in the environment | All five LP-ALM layers target Dataverse; no Dataverse means no deployment target |
| DLP policies configured | Connection references in `_Automation` will fail activation if required connectors are blocked or miscategorized |
| Dataverse auditing enabled | Required for CM-3 change control evidence; must be set post-provisioning (off by default) |
| Managed Environments enabled (Test, Prod) | Enforces the managed solution requirement; without it, the platform does not block direct ad-hoc customization |
| AAD security group mapped to environment | Controls who can access the environment; LP-ALM security roles operate within this boundary |
| Service principal created and assigned as application user | LP-ALM pipelines authenticate exclusively via service principal; this must exist before the first pipeline run |
| ADO variable groups populated | Variable groups must contain environment URLs, client IDs, and key vault secret references before pipelines can execute |

---

### 12.3 Alignment with Power Platform Well-Architected

[Power Platform Well-Architected](https://learn.microsoft.com/en-us/power-platform/well-architected/) is Microsoft's framework for designing workloads across five quality pillars. LP-ALM directly implements the guidance of two pillars and is complementary to the others.

| Well-Architected Pillar | LP-ALM Coverage | Alignment |
|---|---|---|
| **Security** | `_Security`-first deployment, managed solutions in upper environments, zero secrets in source control, service principal auth, field-level security profiles | **Direct** — LP-ALM implements the Security pillar's core recommendations at the solution layer |
| **Operational Excellence** | Per-layer CI/CD pipelines, PAC CLI source control workflow, PR-gated deployments, independent layer rollback, deployment order enforcement | **Direct** — LP-ALM implements the OE pillar's "deploy with confidence" and "safe deployment practices" recommendations |
| **Reliability** | Managed solutions prevent ad-hoc change; per-layer rollback scopes the blast radius of a failed deployment | **Partial** — LP-ALM contributes to reliability through change control but does not address uptime targets, environment-level BCDR, or recovery objectives |
| **Performance Efficiency** | Not addressed | **None** — see [Well-Architected: Performance Efficiency](https://learn.microsoft.com/en-us/power-platform/well-architected/performance-efficiency/) |
| **Experience Optimization** | Not addressed | **None** — see [Well-Architected: Experience Optimization](https://learn.microsoft.com/en-us/power-platform/well-architected/experience-optimization/) |

Use the [Power Platform Well-Architected assessment](https://aka.ms/powa/assessment) to evaluate your workload across all five pillars alongside LP-ALM.

---

### 12.4 Alignment with Power Platform Landing Zones

[Power Platform Landing Zones](https://github.com/microsoft/industry/tree/main/foundations/powerPlatform) is Microsoft's architecture and design methodology for provisioning and governing Power Platform environments at enterprise scale. LP-ALM and Landing Zones address different layers of the same stack.

| Landing Zones Design Area | LP-ALM Coverage | For Guidance Beyond LP-ALM |
|---|---|---|
| Identity & Access Management | LP-ALM defines service principal requirements and security role structure | Use Landing Zones for AAD group design, PIM, and conditional access |
| Security, Governance & Compliance | LP-ALM implements solution-layer secrets hygiene and managed solution enforcement | Use Landing Zones for DLP policy baseline, tenant isolation, and connector classification |
| Environments | LP-ALM defines Dev/Test/Prod deployment model and managed vs. unmanaged solution placement | Use Landing Zones for environment provisioning strategy, Managed Environments enablement, and capacity planning |
| Management & Monitoring | Not addressed by LP-ALM | Use Landing Zones + Application Insights integration, CoE Starter Kit, and Dataverse auditing guidance |
| Platform Automation & DevOps | LP-ALM provides solution deployment pipeline templates and PAC CLI workflow | Landing Zones governs environment provisioning pipelines; LP-ALM governs solution deployment pipelines — both apply |
| Business Continuity & Disaster Recovery | Not addressed by LP-ALM | Use Landing Zones BCDR guidance for environment backup and restore strategy |
| Connectivity & Interoperability | Not addressed by LP-ALM | Use Landing Zones for on-premises data gateway and VNet data gateway configuration |

> **Note:** The Power Platform Landing Zones reference implementation (`microsoft/industry`) was archived in March 2025. The design principles and critical design areas remain valid reference material.

---

### 12.5 Recommended Reading Order

For teams adopting LP-ALM in an enterprise or government context:

1. **[Power Platform Landing Zones](https://github.com/microsoft/industry/tree/main/foundations/powerPlatform)** — establish the platform foundation: environments, DLP policies, IAM, monitoring infrastructure
2. **LP-ALM** — structure your solution decomposition and deployment pipeline within that foundation
3. **[Power Platform Well-Architected](https://learn.microsoft.com/en-us/power-platform/well-architected/)** — validate the completed workload design against quality pillars

LP-ALM assumes Landing Zones prerequisites are met. Well-Architected provides the evaluation lens once the workload is built.

---

*Document Version: 1.0 | May 2026 | LP-ALM Methodology*

*This document is the authoritative reference for the Layered Power Platform ALM methodology. Updates are tracked in source control alongside the solution source they govern. The methodology version aligns with the solution major version.*

---

## Appendix A: Azure Integration Layer Guidance

LP-ALM's five layers govern Power Platform solution decomposition. When a workload connects to Azure services — Azure Functions, Logic Apps, Service Bus, API Management, Event Grid, or others — the resources span two platforms with different lifecycle models. This appendix defines where each piece belongs and when to introduce an optional `_Integration` layer.

---

### A.1 The Fundamental Split

Not everything in an Azure-connected workload belongs inside a Power Platform solution.

| Artifact | Where It Lives | How It Deploys |
|---|---|---|
| Azure Function / Logic App / Service Bus | Azure — Bicep, ARM, or Azure CLI | Separate ADO pipeline; no Power Platform solution |
| Custom connector definition | `_Automation` (or `_Integration` — see A.3) | PAC CLI, same as other solution artifacts |
| Connection reference pointing to the custom connector | `_Automation` (or `_Integration`) | PAC CLI |
| Power Automate flow that calls the Azure API | `_Automation` | PAC CLI |
| Endpoint URL, function key, API key | `_Config` as an environment variable | Manual — never committed, never in a pipeline |
| Managed Identity binding | Azure portal / Bicep | Azure-side; no solution artifact |

The Power Platform side of the integration (connector, connection reference, flows) follows the same layer rules as any other component. The Azure side is infrastructure managed independently.

---

### A.2 Credentials and Endpoint Configuration

The connection between Power Platform and Azure surfaces in `_Config` — not in any committed layer.

- **Endpoint URL** (e.g., `https://{functionapp}.azurewebsites.net/api/{function}`) → environment variable in `_Config`
- **Function key or API key** → environment variable in `_Config`; value set manually per environment; never stored in source control
- **Managed Identity** → preferred over keys; no credential stored anywhere; requires the Power Platform environment's system-assigned identity to be granted a role on the Azure resource

When a flow or connector reads the endpoint from an environment variable, only the variable *name* is committed to source. The value is applied as part of the `_Config` manual step in each environment.

---

### A.3 When to Add a `_Integration` Layer

For simple integrations — a single custom connector and a handful of flows — `_Automation` is sufficient. Introduce a dedicated `_Integration` layer when any of the following conditions apply:

| Condition | Reason to Separate |
|---|---|
| Custom connectors are shared by multiple downstream solutions | Connector becomes a versioned dependency; it needs its own release cadence |
| The Azure-facing components are owned by a different team | Team boundaries should align with solution boundaries |
| Azure infrastructure and Power Platform automation have different deployment gates | Splitting layers allows independent promotion through environments |
| The connector or bridge is reused across more than one project | A shared artifact should not be bundled inside a project-specific `_Automation` |

When `_Integration` is added, the full layer order becomes:

```
_Security → _Core → _Config → _Integration → _Automation → _UI
```

`_Integration` must be fully deployed before `_Automation` because flows in `_Automation` may depend on connection references defined in `_Integration`. The deployment order rule — each layer deploys after its dependencies — still applies.

---

### A.4 Repository and Pipeline Structure

**Repository layout with Azure resources:**

```
repo-root/
  solutions/
    {prefix}_Security/
    {prefix}_Core/
    {prefix}_Integration/       # optional — only if A.3 conditions are met
    {prefix}_Automation/
    {prefix}_UI/
  azure/                         # Azure-side infrastructure
    functions/
    bicep/
    pipelines/
      deploy-azure-infra.yml
  pipelines/
    deploy-security.yml
    deploy-core.yml
    deploy-integration.yml       # optional
    deploy-automation.yml
    deploy-ui.yml
    deploy-all.yml
```

**Pipeline dependency chain with `_Integration`:**

```yaml
# deploy-all.yml — updated dependsOn chain
jobs:
  - job: DeploySecurity
  - job: DeployCore
    dependsOn: DeploySecurity
  - job: ConfigGate          # ManualValidation — apply _Config before proceeding
    dependsOn: DeployCore
  - job: DeployIntegration
    dependsOn: ConfigGate
  - job: DeployAutomation
    dependsOn: DeployIntegration
  - job: DeployUI
    dependsOn: DeployAutomation
```

The Azure infrastructure pipeline (`deploy-azure-infra.yml`) runs independently on its own trigger. It is not chained into the Power Platform deploy-all orchestration — Azure infrastructure and Power Platform solution deployments have different owners and approval gates.

---

### A.5 Security Considerations

| Concern | Recommendation |
|---|---|
| Auth between Power Platform and Azure | Managed Identity preferred; avoids any stored credential |
| Azure Function keys / API keys | `_Config` environment variable only; rotate per environment; never in source control |
| Custom connector API definition | May include base URL — use an environment variable reference; do not hard-code per-environment URLs in the connector definition |
| Pipeline service principal access to Azure | Separate Azure SP with least-privilege role on the specific Azure resource; do not reuse the Power Platform pipeline SP |
| GCC High to Azure Government | Ensure Azure resources are deployed to Azure Government (`*.usgovcloudapi.net`) to match the data boundary; commercial Azure endpoints are not authorized for GCC High workloads |

---

### A.6 The Framework Extension Principle

LP-ALM is intentionally extensible. When a workload grows beyond the five standard layers, the framework's answer is: **add a layer, keep the rules**. The same constraints apply to any new layer:

- It has a single responsibility — one layer, one concern
- It deploys after its dependencies and before its consumers
- It is never merged with `_Config`
- Its deployment is automated; only `_Config` values remain manual
- Schema (tables, columns, relationships) belongs in `_Core`, not in any integration or automation layer

The `_Integration` layer is the most common extension point. Other extension points that teams have used include `_Reporting` (for Power BI dataset bindings and paginated report definitions) and `_Portal` (for Power Pages site components when the portal release cadence diverges from `_UI`). Apply the same design test to any proposed new layer: does it have a distinct deployment dependency, a distinct ownership boundary, or a distinct release cadence? If yes, it earns its own layer.
