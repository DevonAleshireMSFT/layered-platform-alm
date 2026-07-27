---
layout: default
title: Security Role Matrix
nav_order: 5
description: "Template privilege matrix for all LP-ALM custom security roles, including Append/Append To guidance and team configuration."
permalink: /security-roles/
---

# Security Role Privilege Matrix Template

> **Layer:** `_Security`  
> **Purpose:** Document all custom security roles, their target personas, and the privilege level
> assigned per table. Update this file whenever a security role is modified in the `_Security` solution.
>
> This document is the human-readable companion to the security role XML definitions
> in `solutions/{ProjectCode}_Security/src/Roles/`.

---

## Role Inventory

| Role Name | Persona | Description |
|---|---|---|
| `{ProjectCode} - Administrator` | System Administrator | Full access for platform maintainers |
| `{ProjectCode} - Contributor` | Standard User | Create and manage own records |
| `{ProjectCode} - Read Only` | Viewer | Read access only, no modification |
| `{ProjectCode} - Support` | Help Desk / Support Staff | Read + Update for troubleshooting |
| `{ProjectCode} - Automation Service` | Service Account | Used by Power Automate flows |
| `{ProjectCode} - Operations User` | Operations UI User | Least-privilege access for `{ProjectCode}_UI_Operations` |
| `{ProjectCode} - Admin UI Operator` | Admin UI User | Privileged UI access for `{ProjectCode}_UI_Admin`; separate from System Administrator |

---

## Access Level Key

| Code | Dataverse Access Level | Scope |
|---|---|---|
| `None` | None | No access |
| `U` | User | Own records only |
| `BU` | Business Unit | All records in the same Business Unit |
| `PBU` | Parent Business Unit | BU + all child BUs |
| `Org` | Organization | All records in the environment |

## Privilege Key

| Code | Privilege |
|---|---|
| `C` | Create |
| `R` | Read |
| `U` | Update |
| `D` | Delete |
| `A` | Append (associate to another record) |
| `AS` | Append To (have records associated to this) |
| `Asn` | Assign (change record owner) |
| `S` | Share |

---

## Table-Level Privilege Matrix

> Replace table names with actual project tables. Add rows for each custom table.

| Table | Administrator | Contributor | Read Only | Support | Automation Service | Operations User | Admin UI Operator |
|---|---|---|---|---|---|---|---|
| `{prefix}_{table1}` | Org C,R,U,D,A,AS,Asn,S | BU C,R,U,D,A,AS | BU R | BU R,U,A,AS | Org C,R,U,D,A,AS | BU C,R,U,A,AS | Org R,U,A,AS |
| `{prefix}_{table2}` | Org C,R,U,D,A,AS,Asn,S | BU C,R,U,D,A,AS | BU R | BU R,U | Org C,R,U,D,A,AS | BU R,U,A,AS | Org R,U,A,AS |
| `{prefix}_{table3}` | Org C,R,U,D,A,AS,Asn,S | BU R | BU R | BU R | Org R | BU R | Org R |

### Required Relationship Review: Append / Append To

For every lookup column or relationship a role traverses, explicitly document **both**
sides of the relationship. Do not rely on CRUD access to imply association privileges.
Every role that creates, updates, automates, or uses records across a relationship must
have the appropriate Append and Append To entries in this matrix.

| Relationship / Lookup Column | On Table | Role Traversing Relationship | Append Required On | Append To Required On | Verified |
|---|---|---|---|---|---|
| `{prefix}_{parent}id` | `{prefix}_{child}` | `{ProjectCode} - Contributor` | `{prefix}_{child}` (Append) | `{prefix}_{parent}` (Append To) | `YYYY-MM-DD` |
| `{prefix}_{parent}id` | `{prefix}_{child}` | `{ProjectCode} - Operations User` | `{prefix}_{child}` (Append) | `{prefix}_{parent}` (Append To) | `YYYY-MM-DD` |
| `{prefix}_{adminlookup}id` | `{prefix}_{table}` | `{ProjectCode} - Admin UI Operator` | `{prefix}_{table}` (Append) | `{prefix}_{adminparent}` (Append To) | `YYYY-MM-DD` |

Failure to set both Append and Append To results in cryptic "access denied" errors when users
attempt to associate records, even if they have full CRUD access on both tables.

---

## Field Security Profile Matrix

> Field security profiles restrict access at the column level, below table-level privileges.
> Document each profile and which columns it covers.

| Profile Name | Columns Covered | Who Gets This Profile |
|---|---|---|
| `{ProjectCode} - Standard` | All non-restricted columns | Contributor, Read Only, Support |
| `{ProjectCode} - Restricted` | Sensitive columns (list them) | Administrator only |
| `{ProjectCode} - Automation` | Columns written by flows | Automation Service |

### Restricted Column List

| Column Logical Name | Table | Restriction Reason | Profile Required |
|---|---|---|---|
| `{prefix}_{sensitivecolumn}` | `{prefix}_{table}` | PII / sensitive data | `{ProjectCode} - Restricted` |

---

## Miscellaneous Privileges

> Document any non-table-level privileges granted to each role.

| Privilege | Administrator | Contributor | Read Only | Support | Automation Service | Operations User | Admin UI Operator |
|---|---|---|---|---|---|---|---|
| `prvExportToExcel` | ✅ | ✅ | ❌ | ✅ | ❌ | As justified | As justified |
| `prvReadAuditSummary` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | As justified |
| `prvWriteAuditSettings` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `prvGoOffline` | ✅ | ✅ | ❌ | ❌ | ❌ | As justified | ❌ |
| `prvWriteRole` | **Built-in SA only** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

> **Note:** `prvWriteRole` cannot be granted to a custom security role. The pipeline service
> principal requires the **System Administrator built-in role** (not a custom role) to deploy
> security roles. This is a Dataverse platform constraint.

---

## Team Configuration Reference

| Team Name | Team Type | Security Role Assigned | Member Provisioning |
|---|---|---|---|
| `{ProjectCode} Administrators` | Owner | `{ProjectCode} - Administrator` | Manual — provisioned post-deploy |
| `{ProjectCode} Contributors` | Owner | `{ProjectCode} - Contributor` | Manual — provisioned post-deploy |
| `{ProjectCode} Readers` | Owner | `{ProjectCode} - Read Only` | Manual — provisioned post-deploy |
| `{ProjectCode} Support` | Owner | `{ProjectCode} - Support` | Manual — provisioned post-deploy |
| `{ProjectCode} Operations Users` | Owner | `{ProjectCode} - Operations User` | Manual — provisioned post-deploy |
| `{ProjectCode} Admin UI Operators` | Owner | `{ProjectCode} - Admin UI Operator` | Manual — provisioned post-deploy |

**Access level setting for all Owner Teams:** Direct User (Basic) access level and Team privileges

**Rationale:** Prevents team role from granting Business Unit or Organization-wide access to
all team members. Team members acquire the intended team-scoped privileges through team
membership.

> **Reminder:** Team records are environment data — they are not solution components and cannot be
> pipeline-deployed. Teams must be created manually in each environment after solution import.

---

## UI Role Considerations

`{ProjectCode}_UI_Operations` and `{ProjectCode}_UI_Admin` must remain schema-free.
Their roles grant access to existing `_Core` tables and `_Security` privileges only.
Admin UI roles must not be used as a substitute for the Dataverse built-in System
Administrator role required by the pipeline service principal for security-role deployment.

For every command, form, flow trigger, or related-record operation exposed through either
UI solution, add the traversed relationship to the Append / Append To review table above.

---

## Change Log

| Date | Changed By | Change Description | Role Affected |
|---|---|---|---|
| `YYYY-MM-DD` | | Initial role design | All |
