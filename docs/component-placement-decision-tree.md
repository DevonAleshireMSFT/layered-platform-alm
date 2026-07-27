---
layout: default
title: Component Placement
nav_order: 4
description: "Decision tree for determining which LP-ALM layer any Power Platform component belongs in."
permalink: /component-placement/
---

# Component Placement Decision Tree

> Use this guide to determine which LP-ALM layer a Power Platform component belongs in.
> Start at the top and follow the matching branch. When in doubt, check [.ai/layers.md](../.ai/layers.md).

---

## Primary Decision Tree

```
START: I have a Power Platform component to place in a layer.
│
├── Does it CONTROL WHO CAN ACCESS data (security role, field profile)?
│   └── YES → _Security
│
├── Does it DEFINE DATA STRUCTURE (table, column, relationship, view, form)?
│   └── YES → _Core
│       │
│       ├── Is it an environment variable DEFINITION (name, type, default value)?
│       │   └── YES → _Core
│       │
│       └── Is it an environment variable VALUE (actual value for a specific environment)?
│           └── YES → Config Gate deployment data ⚠️ (never committed, never a pipeline artifact)
│
├── Does it INTEGRATE across multiple external systems, shared connections, CUI, or boundaries?
│   └── YES → _Integration (optional governed layer)
│
├── Does it PROCESS OR MOVE DATA (flow, connection, connector)?
│   └── YES → _Automation
│
├── Does it DISPLAY DATA TO A USER (app, site map, dashboard, PCF)?
│   └── YES → _UI_Operations or _UI_Admin (criteria-driven)
│
├── Does it REPORT substantial governed data with a distinct lifecycle?
│   └── YES → _Reporting (optional)
│
├── Is it SYNTHETIC TEST DATA or validation assets with a distinct lifecycle?
│   └── YES → _TestData (optional; never real sensitive production data unless authorized)
│
└── Is it ENVIRONMENT DATA (user record, team record, business unit)?
    └── YES → NOT a solution component. Deploy manually as environment configuration.
```

---

## Detailed Decision Rules by Component Type

### Tables and Columns

| Question | Answer | Layer |
|---|---|---|
| Is this a custom table? | Yes | `_Core` |
| Is this a custom column on a custom table? | Yes | `_Core` |
| Is this a custom column on a standard Dataverse table? | Yes | `_Core` |
| Is this a calculated or rollup column? | Yes | `_Core` |
| Is this a global option set (shared choice)? | Yes | `_Core` |
| Is this a table key (alternate key)? | Yes | `_Core` |
| Is this a table relationship (1:N, N:1, N:N)? | Yes | `_Core` |

### Views and Forms

| Question | Answer | Layer |
|---|---|---|
| Is this a system view (active records, inactive records, lookup view)? | Yes | `_Core` |
| Is this a main form? | Yes | `_Core` |
| Is this a quick view form? | Yes | `_Core` |
| Is this a quick create form? | Yes | `_Core` |
| Is this a card form? | Yes | `_Core` |
| Is this a chart associated with a table? | Yes | `_Core` |

### Security Components

| Question | Answer | Layer |
|---|---|---|
| Is this a custom security role? | Yes | `_Security` |
| Is this a field security profile? | Yes | `_Security` |
| Is this a column security profile-to-column binding? | Yes | `_Security` |
| Is this a user record? | Yes | NOT a solution component |
| Is this a team record? | Yes | NOT a solution component |
| Is this a business unit? | Yes | NOT a solution component |

### Automation Components

| Question | Answer | Layer |
|---|---|---|
| Is this a cloud flow (automated, instant, or scheduled)? | Yes | `_Automation` |
| Is this a business process flow? | Yes | `_Automation` (if workflow-driven) or `_UI_Operations` / `_UI_Admin` (if display-only) |
| Is this a connection reference? | Yes | `_Automation` |
| Is this a custom connector? | Yes | `_Automation` |
| Is this a desktop flow? | Yes | `_Automation` |
| Is this a shared connector or connection reference used across multiple external systems or teams? | Yes | Consider `_Integration` |

### UI Components

| Question | Answer | Layer |
|---|---|---|
| Is this a user-facing operational model-driven app? | Yes | `_UI_Operations` |
| Is this an admin or elevated-access model-driven app? | Yes | `_UI_Admin` |
| Is this a canvas app? | Yes | `_UI_Operations` or `_UI_Admin` by persona and privileges |
| Is this a custom page? | Yes | `_UI_Operations` or `_UI_Admin` by persona and privileges |
| Is this a site map? | Yes | Same UI solution as its app |
| Is this a shared dashboard? | Yes | `_UI_Operations` or `_UI_Admin` by audience |
| Is this a PCF (Power Apps Component Framework) control? | Yes | `_UI_Operations` or `_UI_Admin` by audience |
| Is this a UX-only web resource used for display/rendering? | Yes | UI solution that owns the experience |
| Is this a data-integrity or schema-adjacent web resource used by Core forms? | Yes | `_Core` |

### Multiple Front-End Applications (UI Split Decision)

When a project contains operational and administrative user experiences, use this framework to determine whether both UI solutions are warranted:

| Consideration | One UI solution | Split into `_UI_Operations` and `_UI_Admin` |
|---|---|---|
| Persona boundary | Same audience and privilege level | Admin or elevated-access capability exists |
| Release cadence | Experiences always deploy together | Operations and admin changes release independently |
| Team ownership | Same team maintains both experiences | Different teams own or review admin capability |
| Deployment targets | Always deployed to same environments | Admin app may not deploy to all environments |
| Blast radius tolerance | Acceptable to touch both per release | Need to patch one without touching the other |

**Default:** Use `{ProjectCode}_UI_Operations` for user-facing operational experiences. Add `{ProjectCode}_UI_Admin` when the criteria above justify separate admin capability, privileges, review gates, or blast-radius control.

**Naming:**
```
{ProjectCode}_UI_Operations  → user-facing operational application
{ProjectCode}_UI_Admin       → admin or elevated-access application
```

Both solutions share the same `_Security`, `_Core`, and any optional `_Automation` / `_Integration` layers. Both deploy during the UI phase as sequential imports, not simultaneous. Neither UI solution may contain schema.

### Environment Variables

| Question | Answer | Layer |
|---|---|---|
| Is this the schema definition of an env var (name, type, default)? | Yes | `_Core` |
| Is this the current value of an env var for a specific environment? | Yes | Config Gate deployment data ⚠️ |

Environment variable values are deployment-controlled data supplied through approved secret-backed variables, Key Vault references, or an ephemeral PAC settings file that is generated, used, deleted, and never published as an artifact. A dedicated unmanaged `_Config` solution is allowed only as an optional high-control audit-anchor pattern when justified; it is manually applied, never committed, and never included in pipelines.

### Optional Governed Layers

| Question | Answer | Layer |
|---|---|---|
| Are integrations numerous, shared, separately owned, independently released, or moving CUI / cross-boundary data? | Yes | `_Integration` |
| Are reporting artifacts substantial, governed, or independently released? | Yes | `_Reporting` |
| Are synthetic test datasets or validation assets substantial and lifecycle-managed? | Yes | `_TestData` |

Do not create optional layers just to satisfy a diagram. Record the tier decision and create these layers only when the project facts justify the additional solution boundary.

---

## Edge Cases and Ambiguous Components

### Business Process Flows (BPFs)

BPFs live in an ambiguous space between automation and UI. Use this rule:

```
Does the BPF trigger actions (send emails, update records, call flows)?
  YES → _Automation

Does the BPF only guide users through stages (visual progress indicator)?
  YES → _UI_Operations or _UI_Admin

Does it do both?
  → _Automation (automation takes precedence)
```

### Web Resources

```
Is the physical web-resource file referenced by _Core forms or required for schema-adjacent behavior?
  YES → _Core

Is the physical web-resource file UX-only (icons, custom visualizations, help content, app-specific script)?
  YES → _UI_Operations or _UI_Admin
```

Decide web-resource placement by the **physical file** and Dataverse dependency direction, not by intent alone. `_Core` forms must never depend on UI web resources because that reverses the layer dependency. Client-side JavaScript is not an integrity boundary; enforce true integrity with Dataverse schema, required fields, relationships, business rules, plugins / server-side logic, and security roles.

### Charts

```
Is the chart defined at the table level (system chart, visible in views)?
  YES → _Core

Is the chart embedded in a dashboard (shared dashboard)?
  → Dashboard goes in _UI_Operations or _UI_Admin; the chart definition stays in _Core
```

### Connection References

Connection references are always `_Automation` unless they are promoted into an optional `_Integration` layer as shared integration assets.

The canvas app (`_UI_Operations` or `_UI_Admin`) references a connector, which points to a connection reference (`_Automation` or `_Integration`). The canvas app does not own the connection reference. The app and the connection reference are in different layers with a clean dependency.

If connection references or connectors become shared platform assets across multiple external systems, teams, CUI movement, or cross-boundary services, evaluate `_Integration` before they are widely consumed.

### PCF Controls

PCF controls are always UI — even when they render table data.

A PCF control renders data — it does not define data structure. The column the PCF control is bound to belongs in `_Core`. The control itself belongs in `_UI_Operations` or `_UI_Admin`.

---

## The Schema Contamination Test

Before committing any changes to a UI solution, run this test:

```powershell
# Check for schema contamination in UI solutions
$uiSolutions = @("{ProjectCode}_UI_Operations", "{ProjectCode}_UI_Admin")
foreach ($uiSolution in $uiSolutions) {
    $uiSrcPath = "./solutions/$uiSolution/src/Entities"
    if (Test-Path $uiSrcPath) {
        $items = Get-ChildItem -Path $uiSrcPath -Recurse -File
        if ($items.Count -gt 0) {
            Write-Warning "SCHEMA CONTAMINATION in $uiSolution: $($items.Count) entity files found."
            $items | ForEach-Object { Write-Host "  Move to _Core: $($_.Name)" }
        } else {
            Write-Host "Clean: No schema found in $uiSolution."
        }
    } else {
        Write-Host "Clean: No Entities directory in $uiSolution."
    }
}
```

If this script reports any files, **do not commit**. Move the affected components to `_Core` in the Dev environment, then re-export and re-unpack.

---

## Summary Cheat Sheet

```
_Security     → Who can access what
_Core         → How data is structured
Config Gate   → How deployment values are supplied (never committed)
_Automation   → How data flows and is processed
_Integration  → Shared / governed cross-system integration (optional)
_UI_Operations → User-facing operational experiences
_UI_Admin     → Admin or elevated-access experiences (optional)
_Reporting    → Governed reporting with a distinct lifecycle (optional)
_TestData     → Synthetic test datasets / validation assets (optional)
```
