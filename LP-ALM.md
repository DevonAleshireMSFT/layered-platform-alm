---
layout: default
title: LP-ALM Methodology
nav_order: 2
description: "Complete 11-section methodology reference: layer definitions, security architecture, PAC CLI workflow, ADO pipelines, security role design, and environment strategy."
permalink: /methodology/
render_with_liquid: false
---

# Layered Platform ALM (LP-ALM)
## A Security-First Decomposition Methodology for Enterprise Power Platform Deployments

**Version:** 1.0  
**Date:** May 2026  
**Applicability:** Microsoft Power Platform / Dataverse — Commercial, GCC, GCC High, and other regulated or enterprise contexts

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

Layered Platform ALM (LP-ALM) is a structured application lifecycle management framework for Microsoft Power Platform that decomposes solutions around ordered mandatory invariants plus optional solution layers. `_Security` deploys first, `_Core` owns schema, configuration values never enter source control, upper environments receive managed solutions only, and UI solutions remain schema-free. Optional layers are introduced when the workload has the assets, ownership boundaries, or governance triggers that justify them.

LP-ALM exists because monolithic Power Platform solutions — a single solution containing security roles, data schema, flows, environment variables, connection references, and app components — create a class of problems that compound over time: coupled deployments where a UI change requires a full schema re-import, pipeline secrets exposure from environment-specific values committed to source control, security role gaps when tables are created before access controls exist, and merge conflicts across teams when all components share a single solution artifact.

### 1.2 Who It Is For

LP-ALM is designed for:

- **Enterprise Power Platform teams** managing solutions across multiple environments (Dev, Test, Prod)
- **Government and regulated-industry deployments** operating under FedRAMP, CMMC, FISMA, or HIPAA compliance frameworks
- **Platform architects** building repeatable, auditable delivery pipelines using Azure DevOps and PAC CLI
- **Consulting teams** delivering Power Platform solutions to clients who require documentation of security controls, change management processes, and pipeline architecture

LP-ALM is not appropriate for single-environment prototypes, maker / low-code projects without a dedicated ALM team, or solutions that will never leave a development environment.

### 1.3 Core Value Proposition vs. Monolithic Development

| Dimension | Monolithic ALM | LP-ALM |
|---|---|---|
| Deployment unit | Single solution (everything) | Mandatory `_Security` + `_Core` foundation with optional targeted layers |
| Security posture | Security roles deployed with schema | Security exists before schema |
| Secrets exposure | Environment values in pipelines or source | Values excluded from source; supplied through the Config Gate or justified optional `_Config` |
| Blast radius | Full solution reimport for any change | Layer-scoped change and rollback |
| Team parallelism | One solution, merge conflicts | Layers owned independently |
| Schema protection | Schema can creep via UI solution | `_UI` structurally cannot contain schema |
| Compliance audit | Point-in-time export of monolith | Per-layer, independently auditable artifacts |
| Partial deployment | All-or-nothing | Deploy only the layers that changed |

### 1.4 Security Architecture Statement (ATO/Security Plan Language)

> The Layered Platform ALM methodology implements a defense-in-depth deployment architecture for Microsoft Power Platform. Security roles and field security profiles are established as the first deployment action in every environment, ensuring that access control structures precede the creation of any data schema, application logic, or user interface. Environment-specific configuration values, including connection strings, shared secret references, tenant-specific identifiers, and connection bindings, are classified as deployment-controlled configuration data and are explicitly excluded from source control. Values are supplied through approved secret-backed deployment mechanisms and evidenced by a metadata-only environment configuration register, or by a justified optional unmanaged `_Config` solution when auditors need a solution-artifact evidence trail. All upper-environment deployments use managed solutions, preventing ad-hoc customization and enforcing change control through the pipeline. Pipeline execution uses service principal application users with the minimum privileges needed by the deployed layer and platform constraint. This architecture directly implements NIST SP 800-53 controls AC-2, AC-3, CM-2, CM-3, CM-6, and SA-3, and is designed to support secure deployments in commercial, sovereign, and regulated environments, including Microsoft Azure Government (GCC High).


### 1.5 Authoring Principles

LP-ALM is a secure framework, not an authority over every tenant, agency, or identity policy. Use the following authoring rules when adapting this methodology:

- Use **RECOMMENDED** and **SHOULD** for controls outside the framework's authority. Reserve **MUST**, **REQUIRED**, and equivalent language for genuine framework invariants: `_Security` deploys first, `_Core` owns schema, `_Config` and raw values are never committed, zero secrets are written to source, UI solutions are schema-free, and upper environments receive managed solutions.
- Scope guidance to secure-framework outcomes. Treat GCC High, IL4, IL5, FedRAMP, and similar regulated environments as example contexts where these controls are often useful; do not label a control as GCC High-required unless quoting an external authority.
- Every recommended control SHOULD include a fallback or alternative. For connection references, the recommended default is a dedicated service account; when unavailable, use a least-privilege delegated identity with documented ownership, credential rotation, approval authority, and environment-register evidence.

---

## 2. Layer Definitions

LP-ALM layers deploy according to mandatory dependency invariants, not a fixed expectation to create every possible solution. The sequence is not a convention — it is a dependency contract. Each optional layer is added only when the project has the components or governance boundaries that justify it.

**Mandatory order:** `_Security` → `_Core` → Config Gate → optional `_Integration` → optional `_Automation` → `_UI` / `_UI_Operations` / `_UI_Admin`

**Tier model:**
- **Minimum:** `_Security` + `_Core` + one schema-free UI solution.
- **Standard:** Minimum + `_Automation` when flows, connectors, connection references, scheduled jobs, or automation runtime assets exist.
- **Enterprise:** Standard + `_Integration` and multiple UI solutions when shared integrations, cross-boundary exchange, CUI movement, external ATO dependencies, separate ownership, or release-cadence differences justify them.

The strict invariants do not change: `_Security` deploys first, `_Core` owns schema, values never enter source control, upper environments receive managed solutions only, and UI solutions cannot contain schema.

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
- Environment variable current values (deployment-controlled values supplied through the Config Gate; optional unmanaged `_Config` only when justified)
- Canvas apps (belong in `_UI`)
- Model-driven apps (belong in `_UI`)
- Site maps (belong in `_UI`)
- Dashboards (belong in `_UI`)

> **Environment Variable Definitions vs. Values:** The environment variable *definition* (schema — name, type, default value) belongs in `_Core`. The environment variable *value* (the actual value for a specific environment) is deployment-controlled data. By default, values are supplied through the Config Gate using approved secret-backed variables / Key Vault and an ephemeral `pac solution import --settings-file`; a dedicated unmanaged `_Config` solution is allowed only as a justified high-control alternative and is never committed.

#### Decision Rules

```
Does this component define a table, column, relationship, or view?  → _Core
Does this component define a form?                                   → _Core
Does this component define how data is structured or stored?         → _Core
Does this component define how data is accessed or secured?          → _Security
Does this component define how data is processed or moved?           → _Automation
Does this component define how data is displayed in an app?          → _UI
Is this an environment variable definition (schema only)?            → _Core
Is this an environment variable value?                               → Config Gate value (optional unmanaged _Config only with justification)
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

### 2.3 Configuration Values: Config Gate and Optional `_Config`

**Purpose:** Keep environment-specific values out of source control while proving that each environment has the necessary configuration before dependent layers activate.

**Default pattern:** LP-ALM no longer mandates a dedicated `_Config` solution. The default is the **Config Gate**:

1. Environment variable **definitions** live in `_Core`.
2. Environment variable **values**, connection bindings, endpoint URLs, tenant identifiers, and secrets are supplied at deployment time from approved secret-backed Azure DevOps variables / Key Vault.
3. The pipeline may generate an ephemeral settings file for `pac solution import --settings-file`, use it for the import, and delete it immediately. The settings file is never committed, retained, or published as an artifact.
4. A metadata-only environment configuration register records logical name, environment, owner, necessity status, secret classification, source variable name, approval/change reference, and last-reviewed date. It never records raw values.

**High-control alternative:** A dedicated **unmanaged** `{ProjectCode}_Config` solution remains allowed when auditors require a tangible solution-artifact evidence trail. This is an opt-out from the default with documented justification, not the baseline. It is manually applied, never committed, never published as a pipeline artifact, and never treated as the authoritative source for secrets.

#### Canonical Component List

**Belongs in the Config Gate / optional `_Config`:**
- Environment variable current values (the actual value, not the definition)
- Connection binding data needed by imports or activation
- Endpoint URLs, tenant identifiers, and other environment-specific values

**Does NOT belong in the Config Gate / optional `_Config`:**
- Environment variable definitions (belong in `_Core`)
- Security roles (belong in `_Security`)
- Flows (belong in `_Automation`)
- Any schema component
- Raw secrets in documentation, source control, logs, or artifacts

#### Decision Rules

```
Is this value different in Dev vs. Test vs. Prod?             → Config Gate value
Is this a secret, API key, URL, or tenant identifier?         → Config Gate value / Key Vault-backed secret
Is this a schema definition?                                  → _Core (not configuration)
Is this a flow?                                               → _Automation
Do auditors require a solution-artifact evidence trail?       → Optional unmanaged _Config, justified and never committed
```

#### Source Control Exclusion

**Configuration values are NEVER committed to source control. This is non-negotiable.**

The rationale: environment variable values frequently contain tenant-specific identifiers, endpoint URLs, and other values that differ between environments and cloud boundaries. Committing these values risks:

1. Exposing tenant topology information in a potentially public or audited repository
2. Accidentally deploying values into the wrong environment or cloud boundary
3. Creating a false expectation that source control is the authoritative source for configuration

The authoritative evidence for configuration governance is the environment configuration register plus Key Vault / Azure DevOps audit logs, approvals, and deployment run history. Raw values remain in approved secret storage or in the target environment — not the repository.

#### Deployment Method

**Default:** Config Gate validation before any layer that depends on values or bindings. Values are supplied through approved secret-backed deployment inputs and, when needed, an ephemeral `pac solution import --settings-file` file that is generated, used, deleted, and never retained.

**Optional high-control alternative:** Manually apply an unmanaged `{ProjectCode}_Config` solution only when justified by auditor evidence needs. LP-ALM stops mandating `_Config`; it does not forbid the pattern. Governed defaults apply unless a project opts out with written justification.

#### Pipeline Treatment

Pipelines must not import or publish a `_Config` solution. Pipelines may validate the Config Gate, consume secret-backed variables / Key Vault references, and generate ephemeral settings files that are deleted after use. No raw configuration value may appear in source control, pipeline YAML, logs, artifacts, or documentation.

---

### 2.4 Layer 4: `_Automation`

**Purpose:** Contain process automation when the project actually has automation assets: Power Automate flows, connection references, custom connectors, scheduled jobs, and data-processing logic.

**Scope:** Automation logic only. No schema, no UI, no security definitions. Do not create `_Automation` for a project that genuinely has no flows, connectors, connection references, scheduled jobs, or automation runtime assets.

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
- Environment variable values (deployment-controlled Config Gate values; optional unmanaged `_Config` only when justified)

#### Decision Rules

```
Does this component process, transform, or move data?           → _Automation
Does this component respond to a trigger (create, update, schedule)? → _Automation
Does this component reference a connection?                     → _Automation
Is this a canvas app?                                          → _UI
Is this a model-driven app?                                    → _UI
Does this component define data structure?                      → _Core
Are there no automation runtime assets?                         → omit _Automation
```

#### Dependencies

`_Automation` depends on:
- `_Security` (flows run as users subject to security roles)
- `_Core` (flows reference tables and columns)
- `_Integration` when it consumes shared integration components
- Config Gate readiness (connection reference values and environment variable values are present before activation)

The Config Gate must pass before `_Automation` is deployed or activated. If environment variable values and connection references are not populated, flow activation will fail.

#### Deployment Method

| Environment | Solution Type | Mechanism |
|---|---|---|
| Dev | Unmanaged | PAC CLI import or manual |
| Test | Managed | Azure DevOps pipeline |
| Prod | Managed | Azure DevOps pipeline |

#### Source Control

**Yes.** Flow definitions, connection reference schemas, and environment variable definitions are all committed. Connection reference *values* (the actual credential binding) are populated through the Config Gate and an approved identity binding — not from source control.

#### Connection Reference Binding

Connection references in `_Automation` SHOULD be bound to dedicated service accounts by default, not personal credentials. When a dedicated service account is unavailable, the secure fallback is a least-privilege delegated identity with documented ownership, rotation expectations, approval authority, and environment-register evidence. When the solution is imported to Test or Prod:

1. The connection reference schema is imported as part of the managed solution
2. The connection (the actual credential binding) should be created in the target environment using the approved identity: preferably a dedicated service account, or the documented delegated fallback when a service account is unavailable
3. This binding is applied via a post-import step using PAC CLI or the Power Platform Admin Center
4. Personal credential connections should not be used in shared or upper environments; if a delegated identity is the approved fallback, its owner, rotation process, and continuity plan are documented

> **Sovereign cloud example:** GCC High connection URLs use `.crm.microsoftdynamics.us` instead of `.crm.dynamics.com`. Approved identity connections should use the correct endpoint for the target cloud, and PAC CLI commands should explicitly specify the target environment URL.

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
- Web resources (JavaScript, HTML, images) that are UX-only and app-facing
- Custom pages

**Does NOT belong in `_UI`:**
- Any table, column, or relationship definition (these belong in `_Core`)
- Security roles (belong in `_Security`)
- Flows (belong in `_Automation`)
- Connection references (belong in `_Automation`)
- Environment variables (definitions in `_Core`, values supplied through the Config Gate or justified optional `_Config`)

#### Decision Rules

```
Does this component render data to a user?                           → _UI
Is this a model-driven or canvas app?                               → _UI
Is this a dashboard or chart displayed in an app?                   → _UI
Does this component define a table or column?                        → _Core (not _UI — move it)
Is this a PCF control?                                              → _UI
Is this a web resource used by a form?
  If it enforces data-integrity or schema-adjacent behavior:          → _Core
  If it is UX-only display/rendering behavior:                       → _UI
Would a _Core form need to reference a _UI web resource?             → split the physical files; _Core does not depend on _UI
```

#### The Schema Contamination Rule

`_UI` cannot introduce schema. This is enforced by architecture, not process:

- When building model-driven apps, new columns are added to `_Core` first, then the form in `_Core` is updated, then the app in `_UI` references the updated form
- If a solution checker or manual review finds a table or column component inside `_UI`, it must be moved to `_Core` before the pipeline runs

Violation of this rule causes a hard dependency failure: `_UI` would import a schema component, creating an unmanaged layer in a managed environment, breaking subsequent `_Core` updates.

#### Web Resource Split Rule

Web resources are split by **physical files** and dependency direction, not by intent alone:

- Data-integrity or schema-adjacent web resources needed by `_Core` forms live in `_Core`.
- UX-only web resources used only by apps, command bars, custom pages, or app-specific rendering live in `_UI`, `{ProjectCode}_UI_Operations`, or `{ProjectCode}_UI_Admin`.
- `_Core` forms must never depend on `_UI` web resources. If both concerns exist, split the JavaScript into separate physical files so dependencies point from UI to Core, never from Core to UI.
- Client-side JavaScript is not an integrity boundary. Required fields, relationships, business rules, plugins, server-side logic, and security roles enforce real integrity.

#### Dependencies

`_UI` depends on the mandatory foundation and any optional layers it consumes:
- `_Security` (app access is controlled by security roles)
- `_Core` (apps reference tables, columns, views, and forms)
- Config Gate readiness (apps may reference configured values or connection bindings)
- `_Automation` when apps trigger or display results of flows
- `_Integration` only when the UI directly consumes shared integration components

#### Deployment Method

| Environment | Solution Type | Mechanism |
|---|---|---|
| Dev | Unmanaged | PAC CLI import or manual |
| Test | Managed | Azure DevOps pipeline |
| Prod | Managed | Azure DevOps pipeline |

#### Source Control

**Yes.** All app definitions, site maps, dashboards, and PCF controls are committed.

---

### 2.6 Adapting the Layer Structure

LP-ALM is a governed decomposition model, not a mandate to create empty layers. Project teams select a tier and layer set using the decision model below, then record the choice as an ADR-style decision before implementation. See [docs/lp-alm-refinement-plan.md](docs/lp-alm-refinement-plan.md) for the full refinement plan.

#### Layer Decision Model

1. **Always create `_Security`.** It contains roles, field security profiles, protected data access structures, and anything that must enter Test/Prod before schema.
2. **Always create `_Core`.** It contains all schema: tables, columns, relationships, views, forms, keys, choices, charts, and environment variable definitions.
3. **Default to the Config Gate; do not mandate `_Config`.** Manage values as environment deployment data through secret-backed pipeline variables / Key Vault, the environment configuration register, and Config Gate validation. Values and connection bindings are never committed to source control. A dedicated unmanaged `_Config` solution remains a recognized high-control alternative only when auditors require a solution-artifact evidence trail; it is never committed and is manually applied with documented justification.
4. **Create `_Automation` when automation exists.** Use it for flows, custom connectors, connection references, scheduled jobs, and data-processing logic. Do not create it for a project that genuinely has no flows, connectors, connection references, or scheduled jobs.
5. **Create `_UI` when user-facing artifacts exist.** Use it for model-driven apps, canvas apps, dashboards, site maps, PCF controls, custom pages, and UX web resources. `_UI` cannot contain schema.
6. **Split UI only for distinct ownership, release cadence, deployment target, persona boundary, or blast radius.** Use `{ProjectCode}_UI_Operations` and `{ProjectCode}_UI_Admin` when operational and administrative experiences require separation; avoid splitting merely for preference.
7. **Create `_Integration` only when integrations are shared, numerous, separately owned, independently released, or government-governed as cross-boundary services.** Split before shared connectors become hard to unwind.
8. **Create Reporting or Test Data solutions only when the artifacts are substantial and have an independent lifecycle.** Keep reporting dependencies explicit and keep test data synthetic unless production data use is authorized.

#### Tier Selection Requires Justification

Tier selection should be recorded as an ADR-style decision before implementation. The record should state the selected tier, the facts that justify it, rejected alternatives, and the evidence location for future audit review.

- **Minimum** = `_Security` + `_Core` + one schema-free UI solution. Minimum is allowed only when there are no external integrations, no cross-boundary or CUI data movement, and no privileged admin UI.
- **Standard** = Minimum + `_Automation` when automation exists but integrations are not shared, cross-boundary, or independently governed.
- **Enterprise** = Standard + `_Integration` + multiple UI solutions as warranted. Enterprise is recommended when CUI exchange, shared connection references, cross-system orchestration, separately governed integrations, or external ATO dependencies exist; if a project does not adopt it, document the compensating control and owner.

This prevents teams from choosing a smaller tier to dodge governance. Governed defaults remain the baseline; projects may omit optional layers only with documented justification.

#### Multiple UI Solutions

When a project has distinct operational and administrative front-end applications, both live in the UI layer as separate schema-free solutions:

```
_Security → _Core → Config Gate → optional _Automation → _UI_Operations
                                                       → _UI_Admin
```

Both UI solutions share the same `_Core` schema and any optional `_Automation` / `_Integration` dependencies. Access control between the two apps is enforced in `_Security` — the admin role grants write access to privileged tables; the operational role does not. Both deploy in the UI phase of the pipeline. This is the appropriate pattern when the operational and admin experiences have distinct privileges, review gates, release cadence, or blast radius but do not justify independent `_Core` schemas.

**When to split `_UI` into `{ProjectCode}_UI_Operations` and `{ProjectCode}_UI_Admin`:**

| Consideration | One `_UI` solution | Separate UI solutions |
|---|---|---|
| Release cadence | Both apps always deploy together | Apps have independent release schedules |
| Team ownership | Same team maintains both apps | Different teams own each app |
| Deployment targets | Always deployed to same environments | One app may not deploy to all environments |
| Persona boundary | Same privilege model and review path | Operations and admin capabilities need separation of duties |
| Blast radius tolerance | Acceptable to touch both per release | Need to patch one without touching the other |

The default is **one `_UI` solution**. Split only when one or more of the above "Separate" conditions is true — not as a matter of preference or logical organization. When split, the user-facing operational app is named `{ProjectCode}_UI_Operations`; the admin app is named `{ProjectCode}_UI_Admin`.

#### Optional Azure Integration Layer

When flows call Azure services, the Power Platform-side artifacts (custom connectors, connection references, flows) usually stay in `_Automation`. Add `_Integration` only when multiple external systems, shared connection references, a dedicated integration team, independently governed service connections, cross-boundary data exchange, CUI movement, or external ATO dependency warrants a separate lifecycle. Starting without `_Integration` is safe for simple projects, but refactor cost rises once connectors and connection references become shared platform assets.

#### Multiple Applications Sharing a Data Model

When two or more applications in the same environment share tables, the schema is centralized in a shared `_Core` owned by a platform team. Each application then provides its own optional `_Automation`, `_Integration`, and UI layers that declare a solution dependency on the shared `_Core`. Per-application configuration values remain independent and governed by that application's Config Gate evidence.

The test for any structural adaptation: does the new solution have a distinct ownership boundary, a distinct deployment dependency, or a distinct release cadence? If any of those are true, it warrants its own named solution in the appropriate layer position.

---

## 3. Security Architecture Rationale

### 3.1 Security-First Deployment as a Structural Control

The conventional Power Platform ALM approach deploys security roles alongside or after data schema. This creates a window — often unclosed in test environments — where tables and columns exist without access control applied. In regulated environments, this window is a finding.

LP-ALM eliminates this window by architectural constraint. Security roles must exist in the environment before `_Core` deploys. The Dataverse platform itself enforces dependencies at import time: if `_Security` fails to import, `_Core` cannot proceed. This is not a process rule that can be bypassed by human error — it is a pipeline gate.

The consequence: in every LP-ALM environment, at every point in time, every data structure that exists has a corresponding access control structure that also exists. There is no moment where schema exists without governance.

### 3.2 The Config Gate Pattern: Eliminating Secrets Exposure

The configuration value exclusion from source control addresses a specific, documented class of risk: secrets embedded in repository artifacts.

When environment variable values are committed to source control — either in solution files or as pipeline variable substitutions — those values become persistent, potentially searchable, and subject to repository access controls that are typically broader than the environment access controls. A developer with read access to the repository gains read access to production environment URLs, API keys, and tenant identifiers.

The LP-ALM Config Gate creates a zero-secrets-in-repo guarantee: the repository contains no value that is specific to any environment. A complete clone of the repository cannot yield a working connection to any environment. Credentials remain in the target environments and approved secrets management system (Azure Key Vault), not in version control. The optional unmanaged `_Config` pattern preserves this guarantee because it is never committed, never published as an artifact, and used only with written justification.

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
| AC-2 | Account Management | Service principal application users are provisioned and documented per environment. Personal credential binding is avoided in Test and above. Connection references use managed service accounts where policy permits; when service accounts are unavailable, the environment register documents the approved least-privilege delegated or non-personal identity, owner, rotation plan, and approval authority. |
| AC-3 | Access Enforcement | Security roles deploy before schema (`_Security` first). Every table and column has a corresponding access control structure at all times. Managed solutions prevent unauthorized modification. |
| AC-6 | Least Privilege | Security roles are designed per persona with minimum necessary privileges. Pipeline service principal uses only the built-in System Administrator role for the `_Security` job when `prvWriteRole` is needed — no over-privileging beyond platform constraint. |
| CM-2 | Baseline Configuration | Source control contains the authoritative baseline for committed solution layers (`_Security`, `_Core`, and any optional `_Integration`, `_Automation`, or UI solutions). Configuration values are deployment-controlled artifacts evidenced by the metadata-only environment configuration register, not by committed value files. |
| CM-3 | Configuration Change Control | All changes to committed layers go through pull request review and pipeline validation before deployment. Configuration value changes are controlled through approved secret stores, deployment approvals, environment register updates, and Azure DevOps / Key Vault audit logs. No direct unmanaged customization in Test/Prod is permitted (managed solution enforcement). |
| CM-6 | Configuration Settings | Environment-specific values are supplied through secret-backed deployment inputs / Key Vault and an ephemeral settings file when needed. The environment configuration register records metadata and review evidence. An unmanaged `_Config` solution is optional only when justified as a high-control evidence artifact; no configuration values are hardcoded in pipeline definitions or committed to source. |
| SA-3 | System Development Life Cycle | LP-ALM defines a structured SDLC for Power Platform: development in unmanaged Dev, validation in managed Test, promotion to managed Prod with independent layer sequencing and rollback capability. |
| SI-2 | Flaw Remediation | Layer isolation enables targeted remediation. A security role flaw requires only `_Security` reimport. A flow defect requires only `_Automation` reimport. Neither triggers a full solution deployment. |

### 3.5 Sovereign Cloud Example: GCC High

GCC High (Azure Government, `.us` sovereign cloud) is an example regulated context that diverges from commercial Power Platform in several areas relevant to LP-ALM. Treat this section as implementation guidance for that context, not as the only target for the methodology.

#### Application User Configuration

For GCC High pipeline service connections, use **application users** (service principals registered in Azure Government AD, not commercial Azure AD) rather than interactive login where tenant policy and tooling support it. If local policy requires a different approved authentication pattern, document the exception and evidence in the environment register:

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

For GCC High deployments, PAC CLI commands should use the GCC High URL and connection references should resolve to `.crm.microsoftdynamics.us` endpoints. Connection reference definitions committed to source control should not embed environment-specific URLs — those values are deployment-controlled through the Config Gate or a justified optional `_Config`.

#### Connection References and Service Account Constraints

The recommended default for connection references in all environments is a **dedicated service account** — a licensed user account (not a service principal) with a stable credential, assigned only the `{ProjectCode} - Automation Service` security role, whose connections are used by all flows in that environment.

However, in many DoD agencies and classified programs, service accounts are restricted or prohibited by policy. Common constraints include CAC/PIV-only authentication requirements, zero-standing-access policies, or prohibitions on shared credentials for compliance reasons.

**LP-ALM's position on this constraint:**
- Dedicated service accounts are the recommended default where agency policy permits
- Where service accounts are unavailable, the secure fallback is a least-privilege delegated identity with documented owner, rotation process, approval authority, and environment-register evidence
- Personal credential bindings may be acceptable in individual dev and Integration Dev environments when documented as a dev-only limitation
- For Test and above, use a non-personal credential where available; if unavailable, document the approved delegated fallback or IAM exception before activation
- This is an agency IAM policy question, not an LP-ALM design question — LP-ALM defines secure outcomes and evidence expectations; the project resolves identity mechanics through agency channels

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

Every LP-ALM project uses a single, dedicated publisher. The publisher defines the prefix used for all custom schema components. Sharing publishers across projects is not recommended — it creates namespace collisions.

**Publisher configuration:**

| Field | Guidance |
|---|---|
| Display Name | Human-readable project name (e.g., "SYSTRK Platform") |
| Unique Name | Lowercase, no spaces, no special characters (e.g., `systrkplatform`) |
| Prefix | 2–5 character lowercase abbreviation (e.g., `sys`) |
| Choice Value Prefix | Numeric prefix aligned with prefix (e.g., `10000`) |

**Publisher naming rules:**
- Prefix should be lowercase alphabetic characters only (no numbers, no underscores)
- Prefix should be 2–5 characters
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
  SYSTRK_Automation
  SYSTRK_UI
  SYSTRK_UI_Operations
  SYSTRK_UI_Admin
  SYSTRK_Config   (optional unmanaged evidence pattern only)
```

- `ProjectCode` is uppercase, 3–8 characters, unique per project
- `Layer` is the layer name (the leading underscore is part of the conceptual layer identifier but is omitted from the solution name in this convention)
- Do not include environment names in solution names — the solution name is constant across environments

**Solution unique names (for API/programmatic use):**
```
Format:   {projectcode}_{layer}  (lowercase)
Examples: systrk_security, systrk_core, systrk_automation, systrk_ui, systrk_ui_operations, systrk_ui_admin, systrk_config (optional unmanaged evidence pattern only)
```

### 4.4 Legacy Prefix Handling

When an existing Power Platform project has a schema prefix retained by platform history or migration constraints (e.g., an existing `crm` prefix used across 50 tables), do not rename it. The cost of renaming a schema prefix is extremely high: all column references in flows, apps, and views need to be updated, and the rename is not a rename in Dataverse — it is a delete-and-recreate that destroys data.

**Approach for existing prefix retention:**
1. Register the existing prefix as the publisher prefix for the LP-ALM publisher
2. All new components added under LP-ALM use the same prefix (no schema change for end users)
3. Document in the project's `.ai/context.md` that the prefix differs from what a new project would choose
4. The publisher unique name and display name can reflect the project identity without changing the prefix

**Do not create a second publisher** to "start fresh" alongside an existing one in the same environment. Two publishers with different prefixes in the same environment create component ownership ambiguity and complicate future solutions.

### 4.5 Environment Naming and URL Conventions (GCC High Example)

**Environment naming:**
```
Format:   {OrgCode}-{Environment}
Examples:
  AGENCYNAME-Dev
  AGENCYNAME-Test
  AGENCYNAME-Prod
```

**GCC High URL example:**
```
Dev:  https://agencyname-dev.crm.microsoftdynamics.us
Test: https://agencyname-test.crm.microsoftdynamics.us
Prod: https://agencyname.crm.microsoftdynamics.us
```

**Never hardcode environment-specific URLs in source control.** They are Config Gate values or Azure DevOps variable group values, not repository content.

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
│   ├── deploy-integration.yml  # Optional: deploy _Integration layer
│   ├── deploy-automation.yml   # Optional: deploy _Automation layer
│   ├── deploy-ui.yml           # Deploy _UI / _UI_Operations / _UI_Admin layer
│   ├── deploy-all.yml          # Sequential full deployment with Config Gate
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
    ├── {ProjectCode}_Integration/ # Optional unpacked _Integration solution
    │   └── src/
    ├── {ProjectCode}_Automation/ # Optional unpacked _Automation solution
    │   └── src/
    │       ├── Workflows/
    │       ├── ConnectionReferences/
    │       └── EnvironmentVariableDefinitions/
    └── {ProjectCode}_UI/         # Unpacked _UI solution (or _UI_Operations / _UI_Admin split)
        └── src/
            ├── AppModules/
            ├── CanvasApps/
            ├── SiteMaps/
            └── Dashboards/
```

> **Configuration values and `_Config` artifacts have no folder in the repository.** A dedicated unmanaged `_Config` solution, if justified, is never committed or published as an artifact.

### 5.2 What Is Committed and What Is Not

**Committed (included in source control):**

| Artifact | Location |
|---|---|
| Unpacked `_Security` solution | `solutions/{ProjectCode}_Security/` |
| Unpacked `_Core` solution | `solutions/{ProjectCode}_Core/` |
| Unpacked `_Integration` solution (optional) | `solutions/{ProjectCode}_Integration/` |
| Unpacked `_Automation` solution (when automation exists) | `solutions/{ProjectCode}_Automation/` |
| Unpacked `_UI` / `_UI_Operations` / `_UI_Admin` solution | `solutions/{ProjectCode}_UI*/` |
| Pipeline YAML definitions | `pipelines/` |
| AI context documentation | `.ai/` |
| Methodology and role docs | `docs/` |
| `.gitignore` | Root |

**Explicitly excluded from source control:**

| Artifact | Reason |
|---|---|
| `_Config` solution (packed or unpacked) | Optional unmanaged evidence artifact containing environment-specific values; never source |
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

LP-ALM's export → unpack → commit cycle assumes a single developer working in a Dev environment at a given time. Dataverse has no checkout or lock mechanism — whoever exports last captures the current environment state, regardless of who made which change. In multi-developer teams this creates predictable failure modes that should be addressed by team topology and protocol.

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

When a single Dev environment is shared, the team should adopt an explicit export protocol to prevent overlapping exports:

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

When starting a new feature, or after a significant period of time, an individual dev environment should be synchronized with the current `main` state. Without this, the developer builds against stale schema and their exports will overwrite newer changes.

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
# Populate necessary configuration values for your dev environment here (see Section 6.3)
pac solution import --path "./sync/SYSTRK_Automation.zip" --force-overwrite true --publish-changes false
pac solution import --path "./sync/SYSTRK_UI.zip"         --force-overwrite true --publish-changes true
```

Run this sync at the start of each sprint, after any significant merge to `main`, or any time your individual dev has not been updated in more than a week.

### 5.6.6 Cross-Developer Feature Dependencies

A common scenario: Developer A is building a flow (`_Automation`) that depends on a new column Developer B is adding (`_Core`). Their work is in separate feature branches and separate environments. Developer A cannot build or test their flow until Developer B's column exists.

**Protocol for cross-layer dependencies:**

1. **Schema-first rule.** `_Core` changes should be merged to `test` (or at minimum committed to a feature branch and imported into Integration Dev) before dependent `_Automation` or `_UI` work begins in any environment.

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

**Canvas apps are the hardest case.** Canvas app source files (produced by `pac canvas unpack`) are complex JSON that does not merge cleanly. For canvas apps specifically, assign a single owner for each app. If two developers both need to work on the same canvas app, they should do so serially, not in parallel.

### 5.6.8 Configuration Values in Developer Environments

Each individual dev environment needs its necessary configuration values populated once — either on initial setup or when environment variable definitions change. For teams with many individual dev environments, the default Config Gate protocol can be supported by a lightweight developer reference process.

**Lightweight protocol for individual dev environments:**

- Document the set of environment variable values needed for a functional individual dev environment in a **Config Reference Sheet** stored outside source control (shared encrypted document, team wiki, or Azure Key Vault reference). This is not a committed solution file — it is the human-readable values list that a developer uses to configure their environment manually.
- When a developer sets up a new individual dev environment, they populate necessary values using the Config Reference Sheet or the project-approved secret-backed process.
- When environment variable definitions change (`_Core` change), the Config Reference Sheet and environment configuration register are updated and developers refresh their values on next sync.
- **Individual dev configuration values may differ from Test/Prod.** This is expected — individual dev environments often point to development-tier external systems, not production systems. The Config Reference Sheet should document which values are environment-tier-specific and what the dev-tier values are.

### 5.6.9 Connection Reference Binding in Developer Environments

Connection references in developer environments present a specific challenge in agencies and programs where service accounts are not available or not permitted.

#### Service Accounts — Recommended Default

The recommended default for all environments, including individual dev, is to use a **dedicated service account** bound to connection references:

- A licensed M365/Power Platform service account (a user account, not a service principal) with a non-expiring password or managed credential
- The account is assigned the `{ProjectCode} - Automation Service` security role
- The connection reference in the environment is bound to a connection created under this service account
- No developer's personal credentials appear in shared or upper-environment connections

This approach helps flows continue when individual team members leave or rotate credentials, and supports audit expectations that shared connections are not personally attributable.

#### When Service Accounts Are Not Available

In many DoD agencies and classified programs, provisioning a service account for development purposes is restricted or prohibited by policy. Common constraints include:

- No shared credentials permitted — every account is attributed to an individual
- CAC/PIV-only authentication — service accounts without hardware tokens cannot be provisioned
- Zero standing access policies — no persistent service accounts; all access is just-in-time
- Account lifecycle policies that treat shared accounts as a compliance violation

When service accounts are not available, use the following fallback approach:

**Individual dev and Integration Dev environments:**
- Developers may bind connection references to their own personal credentials in dev environments when no service account or delegated fallback is available
- This is a dev-only fallback and should not be promoted to Test, UAT, or Prod
- Document explicitly in the environment register which connections are personally bound, who owns them, and when they should be rotated or replaced
- Flows may break when that developer rotates credentials or departs — this is a known limitation of personal bindings and accepted only as a documented dev-only risk
- When the developer leaves the project, their personal connections should be re-bound by another team member before the next Integration Dev export

**Test and above:**
- In environments where service accounts are prohibited but functional connections are needed, the team should escalate to the agency's Identity and Access Management (IAM) team and document the approved identity pattern:
  - A formal request for a non-interactive service account, equivalent managed identity, or least-privilege delegated identity for Power Platform connection references
  - The security controls applied to that identity (MFA or conditional access where applicable, role-limited to the `{ProjectCode} - Automation Service` role, rotation expectations)
  - The approval authority granting exception or standard provisioning
  - Environment-register evidence showing owner, rotation date, and fallback continuity plan
- This is not an LP-ALM limitation — it is an agency IAM policy question. LP-ALM documents secure outcomes and evidence expectations; the project team resolves identity mechanics through the agency's standard account provisioning process.

**Pipeline service principals:**
- The `prvWriteRole` requirement (System Administrator for the `_Security` pipeline job) is separate from connection references
- Pipeline service principals authenticate via client secret or certificate — this is typically less restricted than shared user accounts because the credential is managed in Azure Key Vault, not by a human
- If even service principals are restricted, the pipeline should be redesigned around an agency-approved authentication pattern, such as interactive authentication with just-in-time approval; consult the agency's DevSecOps team and document the exception

**Summary by environment tier:**

| Tier | Service Account Available | Service Account Prohibited |
|---|---|---|
| Individual Dev | Use dedicated service account by default | Personal credentials acceptable as a documented dev-only limitation |
| Integration Dev | Use dedicated service account by default | Personal credentials acceptable with documented owner, rotation, and continuity plan |
| Test / SIT | Use dedicated service account by default | Use IAM-approved delegated/non-personal fallback with owner, rotation, and environment-register evidence |
| UAT | Use dedicated service account by default | Use IAM-approved delegated/non-personal fallback with owner, rotation, and environment-register evidence |
| Prod | Use dedicated service account by default | Use IAM-approved delegated/non-personal fallback with owner, rotation, and environment-register evidence |

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

### 6.3 Handling Configuration Values

LP-ALM's default is the Config Gate, not a mandatory `_Config` solution. Environment variable definitions are committed in `_Core`; current values and connection bindings are supplied at deploy time from approved secret-backed sources and documented in the metadata-only environment configuration register.

```bash
# Example only: generate settings file from approved secret-backed deployment inputs
# The generated file is ephemeral, masked in logs, never committed, and never published.
pac solution import \
  --path "./SYSTRK_Core_managed.zip" \
  --settings-file "$(Pipeline.Workspace)/generated-settings.json" \
  --force-overwrite true \
  --publish-changes true

# Delete generated settings file immediately after import
```

The environment configuration register records the non-secret evidence: logical name, environment, owner, necessity status, secret classification, source variable name, approval/change reference, and last-reviewed date. It does not record raw values.

**Optional unmanaged `_Config` evidence pattern:** Use a dedicated unmanaged `{ProjectCode}_Config` solution only when auditors require a solution-artifact evidence trail. It is manually applied, justified in writing, never committed, never unpacked into `solutions/`, and never imported or published by the pipeline.

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

> **Terminology note:** Throughout this section, "pipeline" refers exclusively to **Azure DevOps (ADO) YAML pipelines**. This is distinct from **Power Platform Pipelines**, which is a separate in-product ALM feature available in the Power Platform admin center. LP-ALM does not use Power Platform Pipelines. All pipeline architecture, YAML examples, and variable group references in this section are Azure DevOps constructs.

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
  ├── Job: Config_Gate_Test         (dependsOn: Deploy_Core_Test; validate values / bindings)
  ├── Job: Deploy_Automation_Test   (dependsOn: Config_Gate_Test; only when automation exists)
  └── Job: Deploy_UI_Test           (dependsOn: Deploy_Automation_Test or Config_Gate_Test)

Stage: Manual_Approval             (environment approval gate — requires human sign-off)

Stage: Deploy_Prod
  ├── Job: Deploy_Security_Prod
  ├── Job: Deploy_Core_Prod         (dependsOn: Deploy_Security_Prod)
  ├── Job: Config_Gate_Prod         (dependsOn: Deploy_Core_Prod; validate values / bindings)
  ├── Job: Deploy_Automation_Prod   (dependsOn: Config_Gate_Prod; only when automation exists)
  └── Job: Deploy_UI_Prod           (dependsOn: Deploy_Automation_Prod or Config_Gate_Prod)
```

### 7.3 Pipeline Variables and Variable Groups

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
- Raw configuration values that are not needed by deployment automation
- Connection reference credentials or bindings that are created directly in the environment
- Environment variable current values unless they are approved secret-backed deployment inputs for the Config Gate

### 7.4 Service Connection Setup for GCC High

1. In Azure DevOps, navigate to **Project Settings → Service Connections**
2. Create a new **Power Platform** service connection (or Generic if Power Platform type is unavailable)
3. For GCC High, the server URL should use `https://yourorg.crm.microsoftdynamics.us`
4. Use **Service Principal / Client Secret** authentication (not interactive) where tenant policy permits; otherwise document the approved authentication fallback
5. For GCC High, the App Registration should be in **Azure Government** (`portal.azure.us`), not commercial Azure

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

  # Note: raw configuration values are never validated by packing source artifacts
```

### 7.7 ADO Pipeline as the Release Mechanism

A question that arises when adopting LP-ALM from other ALM approaches is whether a **Dataverse release solution** is needed — a thin solution with no components of its own whose only purpose is to declare dependencies on all other solutions and provide a single versioned, importable artifact.

**LP-ALM does not use a Dataverse release solution. The ADO pipeline is the release mechanism.**

Three structural reasons explain why a Dataverse release solution conflicts with LP-ALM:

| Reason | Explanation |
|---|---|
| Configuration values are not release-solution code | A release solution cannot include secret-backed Config Gate evidence or environment-specific values. Any bundle of the other layers gives the false impression of a complete, self-contained release. |
| Ordering is enforced by the pipeline, not by Dataverse | A release solution imported as a single artifact cannot guarantee `_Security` deploys before schema. The pipeline `dependsOn` chain is the only reliable enforcement. |
| Independent layer rollback is a core capability | A release solution couples all layers into one import unit. Rolling back only `_UI` requires reimporting the entire bundle. Per-layer pipelines support `_UI`-only rollback in under a minute. |

The versioned release artifact in LP-ALM is the **pipeline run** — identified by the ADO build number, branch, and commit SHA. The per-layer managed solution ZIP files published as ADO pipeline artifacts at each run are the auditable, point-in-time artifact record.

**When a Dataverse release solution is appropriate:** Only when there are no pipelines — for example, distributing a packaged product to customers who import manually without an ADO environment, or when deploying directly from the Power Apps maker portal (make.powerapps.com) as a one-time or ad-hoc action. In those scenarios, a release solution that wraps `_Security`, `_Core`, selected optional `_Automation` / `_Integration`, and UI solutions as a single importable artifact is a reasonable substitute — the recipient imports one file and Dataverse resolves internal dependencies in order. Note that configuration values are still excluded and must be supplied through the Config Gate or a justified optional unmanaged `_Config` after import. In any pipeline-driven deployment, a release solution adds coupling without benefit.

### 7.8 Enterprise Multi-Application Pipeline Topology

When a project grows to multiple applications sharing a common `_Core` schema, the single-project pipeline model expands into a two-tier topology: a **Platform pipeline** that owns and publishes the shared layers as versioned artifacts, and per-application **App pipelines** that consume them.

**Ownership boundaries:**

| Component | Owner | Pipeline |
|---|---|---|
| Shared `_Security` (platform roles) | Platform team | Platform pipeline |
| Shared `_Core` (all schema) | Platform team | Platform pipeline |
| App-specific `_Security` (app roles) | App team | App pipeline |
| App-specific `_Automation` | App team | App pipeline |
| App-specific `_UI` (one or more) | App team | App pipeline |
| Configuration values / optional unmanaged `_Config` evidence | Platform + App teams | Config Gate validation only; `_Config` solution never in any pipeline |

**Platform pipeline flow:**

```
Platform pipeline (triggers on platform team branch):
  1. Export _Core from Platform Integration Dev
  2. Pack as managed solution
  3. Publish artifact: {ProjectCode}_Core_v{version}.zip → ADO Artifacts feed
  4. Tag the run: Platform_Core_v1.3.0
```

**App pipeline flow (consuming the platform artifact):**

```
App pipeline (triggers on app team branch):
  1. Download Platform_Core_v{pinnedVersion}.zip from ADO Artifacts
  2. Import _Core (managed) to target environment
  3. Deploy App _Security
  4. Config Gate validation
  5. Deploy App _Automation (if present)
  6. Deploy App _UI  (or _UI_Operations then _UI_Admin if split)
```

App A can pin to `Platform_Core_v1.3.0` while App B independently adopts `Platform_Core_v1.5.0`. Neither app is blocked by the other's release cadence, and no app team can introduce breaking schema changes into the shared `_Core` — only the platform team can publish a new version of it.

**Rules that carry forward unchanged:**
- `_Config` solution artifacts are never part of any pipeline step — platform or application; pipelines may only perform Config Gate validation with secret-backed inputs
- `_Security` always deploys before `_Core` in both the platform pipeline and every app pipeline
- Upper environments receive managed solutions only — the pinned platform artifact is the managed solution ZIP
- GCC High deployments should include `--cloud UsGovHigh` in `pac auth create` commands in both pipelines

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

### 8.3 Append and Append To — Explicit Setting

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

**Owner Team creation is environment data, not solution data.** Owner teams are created after solution import by an administrator — they cannot be solution-deployed. The team configuration expectations are documented in `_Security` layer documentation, but the actual team records are created manually in each environment.

### 8.5 `prvWriteRole` Requirement for Pipeline Service Principals

The `prvWriteRole` privilege — required to deploy security roles — is only available to the built-in **System Administrator** role. It cannot be granted to a custom security role.

**Impact:** The service principal used for the `_Security` layer pipeline job requires the **System Administrator built-in role** in the target environment because of the Dataverse `prvWriteRole` constraint.

**Implementation options:**

1. **Dedicated SP for `_Security`:** Use a separate service principal for the Security layer with System Administrator; use a minimum-privilege SP for remaining layers
2. **Single SP with System Administrator:** Accept System Administrator for one SP and compensate with pipeline access controls (only the pipeline can invoke this SP, not individual developers)
3. **Document the exception:** Either way, document the System Administrator assignment in the security plan as a justified exception, not an oversight

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
- Miscellaneous: only privileges needed by specific flows (explicitly listed)
- This role is assigned to the approved automation identity used by connection references

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

**Multi-application enterprise topology:**
```
Platform Dev → Platform Integration Dev → (platform artifact published to ADO Artifacts)
                                                    ↓
App A Dev → App A Integration Dev → Test → Prod  (consumes pinned platform artifact)
App B Dev → App B Integration Dev → Test → Prod  (consumes pinned platform artifact)
```

In this topology the Platform Integration Dev environment is the canonical export source for `_Core`. App teams maintain separate Integration Dev environments for their own `_Automation` and `_UI` layers. Test and Prod environments may be shared across apps or isolated per app depending on ATO boundary requirements and environment licensing constraints.

For GCC High deployments, a commercial sandbox environment is sometimes maintained alongside the GCC High topology for development tooling access (e.g., Copilot Studio features not yet available in GCC High), with the GCC High Integration Dev as the canonical source for exports when the production boundary requires it.

**Choosing a topology:**

| Condition | Recommended Topology |
|---|---|
| Solo developer or 2-person team | Shared Dev → Test → Prod |
| 3–5 developers, same functional area | Shared Dev → Test → Prod with export protocol |
| 5+ developers | Individual Dev + Integration Dev → Test → Prod |
| Cross-functional team (Security, Core, UI owned separately) | Individual Dev + Integration Dev → Test → Prod |
| Regulated or high-control boundary, any team size | Individual Dev + Integration Dev → SIT → UAT → Prod |

See Section 5.6 for the full multi-developer workflow, export serialization protocol, and Integration Dev operating procedures.

### 9.2 What Is Deployed to Each Environment

| Layer | Dev | SIT/Test | UAT | Prod |
|---|---|---|---|---|
| `_Security` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |
| `_Core` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |
| Config Gate / optional unmanaged `_Config` | Deployment-controlled values; optional manual artifact only if justified | Deployment-controlled values; optional manual artifact only if justified | Deployment-controlled values; optional manual artifact only if justified | Deployment-controlled values; optional manual artifact only if justified |
| `_Automation` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |
| `_UI` | Unmanaged, manual or PAC | Managed, pipeline | Managed, pipeline | Managed, pipeline |

**Key observations:**
- Configuration values are never committed; an unmanaged `_Config` artifact is optional and manual only when justified
- Pipeline automation applies only to Test/Prod (and SIT/UAT in extended topology)
- Dev environments receive unmanaged solutions so developers can iterate without pipeline overhead

### 9.3 Data Residency and Sovereignty (GCC High Example)

GCC High environments are physically isolated in Azure Government regions (USGov Virginia, USGov Texas). Data at rest and in transit does not cross into commercial Azure regions.

**Relevant secure-framework considerations:**
- Development environments for GCC High projects may be in commercial environments for developer tooling access only when policy allows; otherwise keep development inside the authorized boundary
- Any external integration (API, webhook, connector) called from GCC High flows should reside in an authorized boundary or have documented authorization for data egress
- Custom connectors used by `_Automation` should point to authorized endpoints for the target boundary
- Microsoft 365 connectors (SharePoint, Teams, Exchange) used in flows should reference the endpoint family approved for the target tenant

**Data flow documentation:** For ATO or comparable security packages, document the data flow from Power Platform to every external system called by `_Automation` layer flows. Undocumented external data flows are a common finding.

### 9.4 Managed vs. Unmanaged Solution Rules Per Environment Tier

| Rule | Dev | Test/SIT | UAT | Prod |
|---|---|---|---|---|
| Solution type | Unmanaged | Managed | Managed | Managed |
| Can developers make ad-hoc changes? | Yes | No (managed lock) | No (managed lock) | No (managed lock) |
| Changes tracked in pipeline? | No (Dev is sandbox) | Yes | Yes | Yes |
| Rollback mechanism | Re-import previous version | Re-import managed solution from pipeline artifact | Same | Same |
| `_Config` managed? | Never; optional unmanaged evidence only | Never; optional unmanaged evidence only | Never; optional unmanaged evidence only | Never; optional unmanaged evidence only |

**Never deploy a managed solution to Dev.** A managed solution in Dev prevents iteration and will block future unmanaged imports of the same solution name.

---

## 10. Onboarding Guide for New Teams

### 10.1 Starting a New Project with LP-ALM from Scratch

#### Phase 1: Setup (before any development)

1. **Create the publisher** in the Dev environment
   - Display Name: `{Project Name}`
   - Unique Name: `{projectname}` (lowercase, no spaces)
   - Prefix: `{2–5 char lowercase prefix}`

2. **Create the baseline solution shells** in Dev (empty, linked to publisher)
   - `{ProjectCode}_Security`
   - `{ProjectCode}_Core`
   - `{ProjectCode}_Automation` (only when automation assets exist)
   - `{ProjectCode}_Integration` (only when integration criteria are met)
   - `{ProjectCode}_UI` or `{ProjectCode}_UI_Operations` / `{ProjectCode}_UI_Admin`
   - `{ProjectCode}_Config` (optional unmanaged evidence pattern only when justified)

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

3. Configure the Config Gate for each environment:
   - Set or supply environment variable values and connection bindings through approved secret-backed processes
   - Update the metadata-only environment configuration register
   - **Do not commit raw values or `_Config` artifacts**

4. Build `_Automation` if automation assets exist:
   - Create flows in Dev, added to the `_Automation` solution
   - Configure connection references using the approved identity pattern: dedicated service account by default, or documented delegated fallback when unavailable
   - Export, unpack, commit

5. Build `_UI` / `_UI_Operations` / `_UI_Admin`:
   - Create apps, site maps, dashboards in Dev, added to the selected UI solution(s)
   - Add no new columns — all columns must already exist in `_Core`
   - Export, unpack, commit

6. Run the first pipeline to Test:
   - `_Security` → `_Core` → Config Gate → optional `_Automation` → `_UI` / `_UI_Operations` / `_UI_Admin`

#### Phase 3: Steady-State Development

- All changes go through the export → unpack → PR → pipeline cycle
- Configuration value changes are documented in the environment configuration register (not source control)
- Version numbers are bumped per the semantic versioning convention
- PRs require at least one reviewer before merge to `test` or `main`

### 10.2 Common Mistakes and How to Avoid Them

| Mistake | Symptom | Prevention |
|---|---|---|
| Adding a column in `_UI` | Schema contamination; `_UI` managed imports fail in upper environments | Run solution checker before export; review `git diff` for unexpected `Entities/` content inside `_UI` solution folder |
| Committing `_Config` | Secrets or environment-specific values in source control | `.gitignore` excludes `_Config`; add a pre-commit hook that checks for `Config` solution directories |
| Personal credentials in connection references | Flows break when user's account is rotated or deprovisioned | Use a dedicated service account by default; when unavailable, use a documented least-privilege delegated identity with owner, rotation, and environment-register evidence |
| Deploying `_Automation` before Config Gate validation | Flows fail on import or activation due to missing env var values | Pipeline gate: validate necessary values and connection bindings before automation import or activation |
| Wrong publisher prefix | Schema naming inconsistency; solution check failures | Set publisher once at project start; document in `.ai/conventions.md`; do not change |
| App registration in wrong tenant (GCC High) | PAC CLI auth fails; pipeline cannot connect to GCC High environment | Use `portal.azure.us` for GCC High app registrations; verify `--cloud UsGovHigh` flag in all PAC auth commands |
| Deploying managed solution to Dev | Blocks future unmanaged imports of the same solution | Dev always gets unmanaged; enforced by pipeline parameter that maps environment to package type |
| Missing Append / Append To | Users cannot associate records; flows get access denied on relationship operations | Use privilege matrix template; explicitly audit every lookup relationship against the Append/Append To columns |
| Skipping `_Security` deploy after schema changes | New table exists in environment without security role coverage | Pipeline dependency gates prevent `_Core` from deploying without successful `_Security` gate |

### 10.3 Decision Checklist Before First Pipeline Run

- [ ] `_Security` layer exported, unpacked, and committed
- [ ] `_Core` layer exported, unpacked, and committed
- [ ] `_Automation` layer exported, unpacked, and committed if automation assets exist
- [ ] `_UI` / `_UI_Operations` / `_UI_Admin` layer exported, unpacked, and committed as selected
- [ ] Config Gate values and connection bindings prepared for target environment (confirmed — NOT committed); optional unmanaged `_Config` justified if used
- [ ] Service principal application user exists in target environment
- [ ] System Administrator role assigned to service principal in target environment
- [ ] Azure DevOps variable groups created and populated
- [ ] Pipeline service connections configured and connection test passing
- [ ] Connection references in target environment bound to the approved identity pattern: dedicated service account by default, or documented delegated fallback when unavailable
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
- Environment variable values → Config Gate values (optional unmanaged `_Config` only with justification)

**Step 2: Create the baseline solution shells**

Create empty solutions for the mandatory layers and any justified optional layers in the Dev environment, linked to the same publisher as the monolithic solution.

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

**Step 7: Identify configuration values**

Identify all environment variable current values and document them outside source control in the environment configuration register.

**Step 8: Export, unpack, commit all layers**

Run the bulk export script. Review the diff carefully. Commit.

**Step 9: Plan the cutover**

Plan to delete the monolithic solution from Test and Prod before the LP-ALM layers are deployed to avoid component ownership conflicts between managed solutions. Use a maintenance window. Cutover sequence:

1. Export all data (backup)
2. Remove monolithic managed solution from Test/Prod (deletion propagates)
3. Deploy `_Security` → `_Core` → Config Gate → optional `_Automation` → selected UI solution(s)
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

> "LP-ALM is a governed decomposition pattern for Power Platform solutions built around mandatory invariants and optional solution layers. Security roles deploy first — before schema — as a structural control. Configuration values are excluded from source control by design and supplied through the Config Gate. All upper-environment deployments are managed solutions. Each selected layer has its own pipeline job, source control path, and rollback unit. If you break a flow, you redeploy `_Automation`. If you break a table, you redeploy `_Core`. You never redeploy the whole stack for a one-component change."

Technical talking points:
- Pipeline architecture (per-layer jobs, ADO variable groups, dependency gates)
- PAC CLI export/unpack/commit cycle
- Managed solution enforcement and rollback
- Sovereign cloud service principal setup and cloud flag examples
- Branch strategy and PR gates

#### To Security Officers

> "LP-ALM implements a security-first deployment model aligned with NIST 800-53 AC-2, AC-3, CM-2, CM-3, CM-6, and SA-3. Security roles are the first deployment action in every environment — no data structure can exist without a corresponding access control structure. Environment-specific configuration values are excluded from source control, controlled through approved secret-backed deployment mechanisms, and evidenced by a metadata-only environment configuration register plus approval and audit logs. Production changes go through a governed pipeline with PR review. The architecture supports secure deployments in regulated contexts, including GCC High, by documenting service principal authentication, endpoint selection, and approved identity fallbacks."

Security talking points:
- NIST control mapping (see Section 3.4)
- Zero-secrets-in-repo guarantee
- Managed solution change control
- Service principal authentication model
- FedRAMP / sovereign cloud compliance posture and data residency examples

### 11.2 Differentiation from Microsoft's Default ALM Guidance

Microsoft's Power Platform ALM documentation recommends using solutions for deployment and source control. It acknowledges the possibility of multiple solutions per project but stops short of defining a structured layer model.

LP-ALM extends Microsoft's guidance in three meaningful ways:

1. **Security-first deployment order is a structural control, not a convention.** Microsoft's documentation does not prescribe deployment sequence for security roles. LP-ALM makes the sequence non-negotiable and expresses it as a compliance control with NIST mapping.

2. **Config exclusion is an explicit protocol, not a default.** Microsoft's ALM documentation includes environment variables as a standard solution component. LP-ALM explicitly excludes configuration values from source control, uses the Config Gate and environment configuration register as the governed default, and allows unmanaged `_Config` only as a justified high-control evidence pattern.

3. **Sovereign cloud implementation examples.** Microsoft's general Power Platform ALM guidance is written primarily for commercial environments. LP-ALM addresses endpoint selection, Azure Government app registrations, and service principal patterns using GCC High as an example regulated context.

LP-ALM is compatible with Microsoft's Power Platform CoE Starter Kit and does not conflict with Microsoft's ALM Accelerator — it can be adopted alongside both.

### 11.3 When LP-ALM Is Overkill

LP-ALM is not appropriate for:
- **Single-environment solutions** — no deployment pipeline means the layer architecture provides no deployment benefit
- **Prototype and proof-of-concept work** — governed layers, pipelines, and service principals are excessive for short-lived work
- **Maker projects** — low-code makers without ALM tooling should use the simplest solution structure that works
- **Single-person projects without change control requirements** — per-layer pipeline overhead is unnecessary
- **Solutions that will never go to a regulated environment** — compliance posture features add complexity with no return

**Reasonable threshold for adoption:** LP-ALM is appropriate when the project has two or more of the following: multiple environments, a team of two or more makers, a compliance requirement, or an expectation of 12+ months of active development.

### 11.4 Recommended Deliverables for Consulting Engagements

| Deliverable | Description | Primary Owner |
|---|---|---|
| LP-ALM Methodology Document | This document, customized with project code, prefix, and environment details | Architect |
| Publisher and Solution Setup | Mandatory and justified optional solutions created in Dev, publisher configured, prefix documented | Architect |
| Source Control Repository | Initialized repo with `.gitignore`, `.ai/` structure, `pipelines/`, `docs/` | Architect |
| Pipeline YAML Files | All six pipeline files (5 deploy + 1 PR validation) | Architect |
| Security Role Matrix | Table of roles, tables, and privilege levels per persona | Security Lead |
| Environment Register | Environment URLs, types, access contacts (no secrets) | Architect |
| ADO Variable Groups | Created and documented; secrets populated by customer | Architect + Customer |
| Service Principal Setup Guide | App registration steps, application user setup, role assignment | Architect |
| Onboarding Runbook | Steps for a new developer to get productive in the project | Architect |
| Config Management Protocol | Written procedure for Config Gate handling and optional unmanaged `_Config` justification (document in deliverable set, not source control) | Architect |

**Estimated engagement scope:** 8–16 hours for greenfield setup; 24–40 hours for monolithic migration depending on solution complexity.

---

## 12. Platform Prerequisites & Complementary Guidance

### 12.1 What LP-ALM Governs (and What It Does Not)

LP-ALM governs what is **inside a solution artifact** and how that artifact moves between environments. It does not govern the platform layer — the tenant-level, environment-level, and infrastructure configuration that should exist, or have an approved fallback, before LP-ALM pipelines run successfully.

This boundary is intentional. Platform governance responsibilities — DLP policies, environment provisioning, Managed Environments configuration, monitoring infrastructure, BCDR — are typically owned by a central Power Platform admin team and are documented in Microsoft's own reference frameworks. Reproducing that guidance here would create a maintenance burden and risk drift from Microsoft's authoritative documentation.

LP-ALM is **composable with** Microsoft's platform governance frameworks. It sits at the solution layer; the frameworks below sit at the platform layer.

---

### 12.2 Platform Prerequisites

The following prerequisites should be confirmed in each target environment before LP-ALM pipelines run. These are platform admin responsibilities, not LP-ALM responsibilities; if a prerequisite is unavailable, document the approved platform fallback before deployment.

| Prerequisite | Why LP-ALM Depends On It |
|---|---|
| Dataverse provisioned in the environment | All five LP-ALM layers target Dataverse; no Dataverse means no deployment target |
| DLP policies configured | Connection references in `_Automation` will fail activation if needed connectors are blocked or miscategorized |
| Dataverse auditing enabled | Recommended for CM-3 change control evidence; set post-provisioning where policy permits (off by default) |
| Managed Environments enabled (Test, Prod) | Enforces the managed solution requirement; without it, the platform does not block direct ad-hoc customization |
| AAD security group mapped to environment | Controls who can access the environment; LP-ALM security roles operate within this boundary |
| Service principal created and assigned as application user | Recommended default for LP-ALM pipelines; if unavailable, document the approved authentication fallback before the first pipeline run |
| ADO variable groups populated | Variable groups contain environment URLs, client IDs, and key vault secret references before pipelines execute |

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

*This document is the authoritative reference for the Layered Platform ALM methodology. Updates are tracked in source control alongside the solution source they govern. The methodology version aligns with the solution major version.*

---

## Appendix A: Azure Integration Layer Guidance

LP-ALM's mandatory invariants and optional layers govern Power Platform solution decomposition. When a workload connects to Azure services — Azure Functions, Logic Apps, Service Bus, API Management, Event Grid, or others — the resources span two platforms with different lifecycle models. This appendix defines where each piece belongs and when to introduce an optional `_Integration` layer.

---

### A.1 The Fundamental Split

Not everything in an Azure-connected workload belongs inside a Power Platform solution.

| Artifact | Where It Lives | How It Deploys |
|---|---|---|
| Azure Function / Logic App / Service Bus | Azure — Bicep, ARM, or Azure CLI | Separate ADO pipeline; no Power Platform solution |
| Custom connector definition | `_Automation` (or `_Integration` — see A.3) | PAC CLI, same as other solution artifacts |
| Connection reference pointing to the custom connector | `_Automation` (or `_Integration`) | PAC CLI |
| Power Automate flow that calls the Azure API | `_Automation` | PAC CLI |
| Endpoint URL, function key, API key | Config Gate value / environment variable current value | Secret-backed deployment input or justified optional unmanaged `_Config`; never committed |
| Managed Identity binding | Azure portal / Bicep | Azure-side; no solution artifact |

The Power Platform side of the integration (connector, connection reference, flows) follows the same layer rules as any other component. The Azure side is infrastructure managed independently.

---

### A.2 Credentials and Endpoint Configuration

The connection between Power Platform and Azure surfaces as deployment-controlled configuration data — not in any committed layer.

- **Endpoint URL** (e.g., `https://{functionapp}.azurewebsites.net/api/{function}`) → environment variable current value supplied through the Config Gate
- **Function key or API key** → Key Vault / secret-backed environment variable current value; never stored in source control
- **Managed Identity** → preferred over keys; no credential stored anywhere; requires the Power Platform environment's system-assigned identity to be granted a role on the Azure resource

When a flow or connector reads the endpoint from an environment variable, only the variable *name* and definition are committed to source. The value is supplied through the Config Gate and evidenced by the environment configuration register; optional unmanaged `_Config` is used only with documented justification.

---

### A.3 When to Add a `_Integration` Layer

For simple integrations — a single custom connector and a handful of flows — `_Automation` is sufficient. Introduce a dedicated `_Integration` layer when multiple external systems, shared connection references, a dedicated integration team, or any of the following conditions apply:

| Condition | Reason to Separate |
|---|---|
| Custom connectors are shared by multiple downstream solutions | Connector becomes a versioned dependency; it needs its own release cadence |
| The Azure-facing components are owned by a different team | Team boundaries should align with solution boundaries |
| Azure infrastructure and Power Platform automation have different deployment gates | Splitting layers allows independent promotion through environments |
| The connector or bridge is reused across more than one project | A shared artifact should not be bundled inside a project-specific `_Automation` |
| CUI moves across a boundary or the exchange crosses authorization boundaries | Government evidence, approval, and monitoring responsibilities differ from app automation |
| An external ATO dependency exists | Integration release and risk acceptance may need separate tracking |

When `_Integration` is added, the full layer order becomes:

```
_Security → _Core → Config Gate → _Integration → _Automation → _UI
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
  - job: ConfigGate          # Validate deployment-controlled values / bindings before proceeding
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
| Azure Function keys / API keys | Key Vault / secret-backed configuration value only; rotate per environment; never in source control |
| Custom connector API definition | May include base URL — use an environment variable reference; do not hard-code per-environment URLs in the connector definition |
| Pipeline service principal access to Azure | Separate Azure SP with least-privilege role on the specific Azure resource; do not reuse the Power Platform pipeline SP |
| GCC High to Azure Government | Prefer Azure Government resources (`*.usgovcloudapi.net`) to match the data boundary; if an endpoint crosses boundaries, document the authorization and data-flow evidence |

---

### A.6 The Framework Extension Principle

LP-ALM is intentionally extensible. When a workload grows beyond the standard tier selected for the project, the framework's answer is: **add a layer, keep the rules**. The same constraints apply to any new layer:

- It has a single responsibility — one layer, one concern
- It deploys after its dependencies and before its consumers
- It is never merged with configuration value artifacts
- Its deployment is automated; configuration values remain deployment-controlled through the Config Gate or justified optional unmanaged `_Config`
- Schema (tables, columns, relationships) belongs in `_Core`, not in any integration or automation layer

The `_Integration` layer is the most common extension point. Other extension points that teams have used include `_Reporting` (for Power BI dataset bindings and paginated report definitions) and `_Portal` (for Power Pages site components when the portal release cadence diverges from `_UI`). Apply the same design test to any proposed new layer: does it have a distinct deployment dependency, a distinct ownership boundary, or a distinct release cadence? If yes, it earns its own layer.
