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
│           └── YES → _Config  ⚠️ (never committed, never in pipeline)
│
├── Does it PROCESS OR MOVE DATA (flow, connection, connector)?
│   └── YES → _Automation
│
├── Does it DISPLAY DATA TO A USER (app, site map, dashboard, PCF)?
│   └── YES → _UI
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
| Is this a business process flow? | Yes | `_Automation` (if workflow-driven) or `_UI` (if display-only) |
| Is this a connection reference? | Yes | `_Automation` |
| Is this a custom connector? | Yes | `_Automation` |
| Is this a desktop flow? | Yes | `_Automation` |

### UI Components

| Question | Answer | Layer |
|---|---|---|
| Is this a model-driven app? | Yes | `_UI` |
| Is this a canvas app? | Yes | `_UI` |
| Is this a custom page? | Yes | `_UI` |
| Is this a site map? | Yes | `_UI` |
| Is this a shared dashboard? | Yes | `_UI` |
| Is this a PCF (Power Apps Component Framework) control? | Yes | `_UI` |
| Is this a web resource used for display/rendering in a form? | Yes | `_UI` |
| Is this a web resource that defines column validation logic? | Yes | `_Core` |

### Environment Variables

| Question | Answer | Layer |
|---|---|---|
| Is this the schema definition of an env var (name, type, default)? | Yes | `_Core` |
| Is this the current value of an env var for a specific environment? | Yes | `_Config` ⚠️ |

---

## Edge Cases and Ambiguous Components

### Business Process Flows (BPFs)

BPFs live in an ambiguous space between automation and UI. Use this rule:

```
Does the BPF trigger actions (send emails, update records, call flows)?
  YES → _Automation

Does the BPF only guide users through stages (visual progress indicator)?
  YES → _UI

Does it do both?
  → _Automation (automation takes precedence)
```

### Web Resources

```
Does the web resource define or validate data (JavaScript that sets/validates column values)?
  YES → _Core (it is schema-adjacent behavior)

Does the web resource render something (icons, custom visualizations, help content)?
  YES → _UI
```

### Charts

```
Is the chart defined at the table level (system chart, visible in views)?
  YES → _Core

Is the chart embedded in a dashboard (shared dashboard)?
  → Dashboard goes in _UI; the chart definition stays in _Core
```

### Connection References

Connection references are always `_Automation` — even when a canvas app uses them.

The canvas app (`_UI`) references a connector, which points to a connection reference (`_Automation`). The canvas app does not own the connection reference. The app and the connection reference are in different layers with a clean dependency.

### PCF Controls

PCF controls are always `_UI` — even when they render table data.

A PCF control renders data — it does not define data structure. The column the PCF control is bound to belongs in `_Core`. The control itself belongs in `_UI`.

---

## The Schema Contamination Test

Before committing any changes to the `_UI` solution, run this test:

```powershell
# Check for schema contamination in _UI
$uiSrcPath = "./solutions/{ProjectCode}_UI/src/Entities"
if (Test-Path $uiSrcPath) {
    $items = Get-ChildItem -Path $uiSrcPath -Recurse -File
    if ($items.Count -gt 0) {
        Write-Warning "SCHEMA CONTAMINATION in _UI: $($items.Count) entity files found."
        $items | ForEach-Object { Write-Host "  Move to _Core: $($_.Name)" }
    } else {
        Write-Host "Clean: No schema found in _UI."
    }
} else {
    Write-Host "Clean: No Entities directory in _UI."
}
```

If this script reports any files, **do not commit**. Move the affected components to `_Core` in the Dev environment, then re-export and re-unpack.

---

## Summary Cheat Sheet

```
_Security  → Who can access what
_Core      → How data is structured
_Config    → What the values are (never committed)
_Automation → How data flows and is processed
_UI        → How data is presented
```
