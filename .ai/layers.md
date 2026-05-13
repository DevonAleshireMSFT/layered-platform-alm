# LP-ALM Layer Quick Reference

> Use this file to answer the question: **"Where does this component go?"**
> If you're unsure, start here. Then check `component-placement-decision-tree.md` for edge cases.

---

## Layer 1: `_Security`

**One-line purpose:** Establish access control before anything else exists.

**Belongs here:**
- Custom security roles
- Field security profiles
- Column security profile-to-column bindings

**Does NOT belong here:**
- Tables or columns (→ `_Core`)
- Flows (→ `_Automation`)
- Apps (→ `_UI`)
- Users, teams, business units (→ environment data, not solution components)

**Deploys:** First, always, in every environment  
**Source control:** ✅ Yes  
**Pipeline:** ✅ Yes (requires System Administrator service principal for `prvWriteRole`)  
**Solution type in upper environments:** Managed

---

## Layer 2: `_Core`

**One-line purpose:** Define all Dataverse schema — the single source of truth for data structure.

**Belongs here:**
- Custom tables
- Custom columns (all types)
- Table relationships (1:N, N:1, N:N)
- Global option sets
- System views (active, inactive, lookup, associated)
- Main forms, quick view forms, quick create forms, card forms
- Charts
- Table keys (alternate keys)
- Calculated and rollup column definitions
- Environment variable **definitions** (schema only — name, type, default value)

**Does NOT belong here:**
- Security roles (→ `_Security`)
- Environment variable **values** (→ `_Config`)
- Flows (→ `_Automation`)
- Apps, site maps, dashboards (→ `_UI`)

**Deploys:** Second (after `_Security`)  
**Source control:** ✅ Yes  
**Pipeline:** ✅ Yes  
**Solution type in upper environments:** Managed

---

## Layer 3: `_Config`

**One-line purpose:** Carry environment-specific values that cannot be environment-agnostic.

**Belongs here:**
- Environment variable **current values** (the actual value for a specific environment)
- Nothing else

**Does NOT belong here:**
- Environment variable definitions (→ `_Core`)
- Any schema (→ `_Core`)
- Any flows (→ `_Automation`)
- Any apps (→ `_UI`)

**Deploys:** Manually only — between `_Core` and `_Automation`  
**Source control:** ❌ **NEVER** — absolute rule, no exceptions  
**Pipeline:** ❌ **NEVER** — pipelines must not reference, import, or validate `_Config`  
**Solution type in upper environments:** Unmanaged (manual import only)

---

## Layer 4: `_Automation`

**One-line purpose:** Contain all Power Automate flows and the connection references they depend on.

**Belongs here:**
- Cloud flows (automated, instant, scheduled)
- Connection references
- Business process flows (if workflow-driven)
- Desktop flows
- Custom connectors (if project-owned)

**Does NOT belong here:**
- Table or column definitions (→ `_Core`)
- Canvas apps (→ `_UI`)
- Model-driven apps (→ `_UI`)
- Security roles (→ `_Security`)
- Environment variable definitions (→ `_Core`)
- Environment variable values (→ `_Config`)

**Deploys:** Fourth — after `_Core` and `_Config` (manual) are in place  
**Source control:** ✅ Yes  
**Pipeline:** ✅ Yes  
**Solution type in upper environments:** Managed  
**Pre-condition:** `_Config` must be manually applied first (env vars + connection reference bindings)

---

## Layer 5: `_UI`

**One-line purpose:** Contain all user-facing application components — renders data, defines nothing.

**Belongs here:**
- Model-driven apps
- Canvas apps
- Custom pages
- Site maps
- Shared dashboards
- PCF (Power Apps Component Framework) controls
- Web resources that are display/rendering components

**Does NOT belong here:**
- Tables or columns (→ `_Core`) — **The Schema Contamination Rule**
- Security roles (→ `_Security`)
- Flows or connection references (→ `_Automation`)
- Environment variables (→ `_Core` / `_Config`)

**Deploys:** Fifth (last) — depends on all preceding layers  
**Source control:** ✅ Yes  
**Pipeline:** ✅ Yes  
**Solution type in upper environments:** Managed  
**Warning:** If solution checker or `git diff` shows `Entities/` content inside this folder, stop and move it to `_Core` before proceeding.

---

## Quick Decision Matrix

| I have a... | It goes in... |
|---|---|
| Custom table | `_Core` |
| Custom column | `_Core` |
| Table relationship | `_Core` |
| System view | `_Core` |
| Form (main, quick view, quick create) | `_Core` |
| Global option set | `_Core` |
| Chart | `_Core` |
| Environment variable definition | `_Core` |
| Security role | `_Security` |
| Field security profile | `_Security` |
| Cloud flow (automated/instant/scheduled) | `_Automation` |
| Connection reference | `_Automation` |
| Business process flow | `_Automation` |
| Custom connector | `_Automation` |
| Model-driven app | `_UI` |
| Canvas app | `_UI` |
| Site map | `_UI` |
| Shared dashboard | `_UI` |
| PCF control | `_UI` |
| Web resource (display/rendering) | `_UI` |
| Web resource (tied to schema validation) | `_Core` |
| Environment variable value | `_Config` (manual, never committed) |
| User record | Not a solution component — environment data |
| Team record | Not a solution component — environment data |
| Business unit | Not a solution component — environment data |
