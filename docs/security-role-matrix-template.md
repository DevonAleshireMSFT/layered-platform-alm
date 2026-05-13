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

| Table | Administrator | Contributor | Read Only | Support | Automation Service |
|---|---|---|---|---|---|
| `{prefix}_{table1}` | Org C,R,U,D,A,AS,Asn,S | BU C,R,U,D,A,AS | BU R | BU R,U,A,AS | Org C,R,U,D,A,AS |
| `{prefix}_{table2}` | Org C,R,U,D,A,AS,Asn,S | BU C,R,U,D,A,AS | BU R | BU R,U | Org C,R,U,D,A,AS |
| `{prefix}_{table3}` | Org C,R,U,D,A,AS,Asn,S | BU R | BU R | BU R | Org R |

### Notes on Append / Append To

For every lookup column in the schema, verify **both** sides of the relationship are covered:

| Lookup Column | On Table | Append Required On | Append To Required On |
|---|---|---|---|
| `{prefix}_{parent}id` | `{prefix}_{child}` | `{prefix}_{child}` (Append) | `{prefix}_{parent}` (Append To) |

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

| Privilege | Administrator | Contributor | Read Only | Support | Automation Service |
|---|---|---|---|---|---|
| `prvExportToExcel` | ✅ | ✅ | ❌ | ✅ | ❌ |
| `prvReadAuditSummary` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `prvWriteAuditSettings` | ✅ | ❌ | ❌ | ❌ | ❌ |
| `prvGoOffline` | ✅ | ✅ | ❌ | ❌ | ❌ |
| `prvWriteRole` | **Built-in SA only** | ❌ | ❌ | ❌ | ❌ |

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

**Access level setting for all teams:** Direct User (Basic)  
**Rationale:** Prevents team role from granting Organization-wide access to all team members.
Team members acquire User-scoped access through team membership.

> **Reminder:** Team records are environment data — they are not solution components and cannot be
> pipeline-deployed. Teams must be created manually in each environment after solution import.

---

## Change Log

| Date | Changed By | Change Description | Role Affected |
|---|---|---|---|
| `YYYY-MM-DD` | | Initial role design | All |
