---
layout: default
title: Environment Register
nav_order: 6
description: "Authoritative non-secret environment and configuration evidence register for CM-2, CM-3, and CM-6. No secrets."
permalink: /environment-register/
---

# Environment Register

> **What this is:** The authoritative reference for all Power Platform environments and
> non-secret configuration evidence in this project.
>
> **What this is NOT:** A secrets store. No client secrets, passwords, API keys, connection
> strings, tenant secrets, environment variable values, or raw configuration values are recorded
> here. Secrets live in Azure Key Vault and Azure DevOps variable groups only.
>
> **Who maintains this:** The platform architect. Update when environments are created,
> decommissioned, configuration metadata changes, approvals change, or evidence is reviewed.
>
> This register is the authoritative non-secret configuration evidence record for **CM-2
> baseline configuration**, **CM-3 configuration change control**, and **CM-6 configuration
> settings**. Now that `_Config` is not a mandated solution, this register proves
> configuration-value governance by recording metadata only and linking to the approved
> source of values, approvals, and deployment evidence.

---

## Environment Summary

| Environment | Type | Purpose | Solution Type | Pipeline? |
|---|---|---|---|---|
| Dev | Sandbox / Unmanaged | Active development | Unmanaged only | ❌ No |
| Test | Managed | Integration testing and validation | Managed only | ✅ Yes |
| Prod | Managed | Production | Managed only | ✅ Yes |

---

## Environment Details

### Dev

| Field | Value |
|---|---|
| **Display Name** | `{OrgCode}-Dev` |
| **Environment ID** | *(retrieve from admin center — do not hardcode in pipelines)* |
| **URL** | `https://{org}-dev.crm.microsoftdynamics.us` |
| **Cloud** | GCC High (`UsGovHigh`) |
| **Type** | Sandbox |
| **Region** | USGov Virginia / USGov Texas |
| **Dataverse** | Yes |
| **Owner / Admin Contact** | `{name@agency.gov}` |
| **Service Principal (App ID)** | ADO variable / Key Vault reference only — value stored outside this file |
| **Solution Type Deployed** | Unmanaged |
| **Who Can Deploy** | Developers (manual) |
| **Managed By** | {Team or Person} |
| **Created** | `YYYY-MM-DD` |
| **Notes** | |

---

### Test

| Field | Value |
|---|---|
| **Display Name** | `{OrgCode}-Test` |
| **Environment ID** | *(retrieve from admin center)* |
| **URL** | `https://{org}-test.crm.microsoftdynamics.us` |
| **Cloud** | GCC High (`UsGovHigh`) |
| **Type** | Sandbox |
| **Region** | USGov Virginia / USGov Texas |
| **Dataverse** | Yes |
| **Owner / Admin Contact** | `{name@agency.gov}` |
| **Service Principal (App ID)** | ADO variable / Key Vault reference only — value stored outside this file |
| **Solution Type Deployed** | Managed |
| **Who Can Deploy** | Azure DevOps pipeline only |
| **Pipeline Variable Group** | `{ProjectCode}-Test` |
| **Managed By** | {Team or Person} |
| **Created** | `YYYY-MM-DD` |
| **Notes** | |

---

### Prod

| Field | Value |
|---|---|
| **Display Name** | `{OrgCode}` |
| **Environment ID** | *(retrieve from admin center)* |
| **URL** | `https://{org}.crm.microsoftdynamics.us` |
| **Cloud** | GCC High (`UsGovHigh`) |
| **Type** | Production |
| **Region** | USGov Virginia / USGov Texas |
| **Dataverse** | Yes |
| **Owner / Admin Contact** | `{name@agency.gov}` |
| **Service Principal (App ID)** | ADO variable / Key Vault reference only — value stored outside this file |
| **Solution Type Deployed** | Managed |
| **Who Can Deploy** | Azure DevOps pipeline only (with manual approval gate) |
| **Pipeline Variable Group** | `{ProjectCode}-Prod` |
| **Managed By** | {Team or Person} |
| **Created** | `YYYY-MM-DD` |
| **Notes** | |

---

## Service Principal Inventory

> App registrations used for pipeline automation. Secrets are stored in Azure Key Vault
> or Azure DevOps variable groups — not in this file.

| Environment | App Name | App ID Reference | Tenant Reference | Role in Environment | Created By | Expires |
|---|---|---|---|---|---|---|
| All | `{ProjectCode}-Pipeline-SP` | ADO variable / Key Vault reference only | ADO variable / Key Vault reference only | Built-in System Administrator | | `YYYY-MM-DD` |

> **GCC High Note:** App registrations for GCC High environments must be created in the
> Azure Government tenant (`portal.azure.us`), not the commercial Azure portal.

---

## Configuration Evidence Register (CM-2 / CM-3 / CM-6)

> This table records metadata only. It proves that required configuration values are
> identified, owned, approved, and reviewed without storing the values themselves.
> Record the source variable name or Key Vault reference name, never the source value.

| Logical Name | Environment | Owner | Required / Optional | Secret Classification | Source Variable Name / Key Vault Reference | Approval / Change Reference | Last Reviewed |
|---|---|---|---|---|---|---|---|
| `{prefix}_{environmentvariable}` | Dev | `{team-or-role}` | Required | Non-secret / Secret / Key Vault-backed | `{ProjectCode}-Dev:{VariableName}` or `{KeyVaultName}:{SecretName}` | `{ADO work item / PR / CAB ID}` | `YYYY-MM-DD` |
| `{prefix}_{environmentvariable}` | Test | `{team-or-role}` | Required | Non-secret / Secret / Key Vault-backed | `{ProjectCode}-Test:{VariableName}` or `{KeyVaultName}:{SecretName}` | `{ADO work item / PR / CAB ID}` | `YYYY-MM-DD` |
| `{prefix}_{environmentvariable}` | Prod | `{team-or-role}` | Required | Non-secret / Secret / Key Vault-backed | `{ProjectCode}-Prod:{VariableName}` or `{KeyVaultName}:{SecretName}` | `{ADO work item / PR / CAB ID}` | `YYYY-MM-DD` |

### Evidence Links

| Evidence Type | System of Record | Reference |
|---|---|---|
| Configuration owner approval | Azure DevOps / CAB / change system | `{approval-reference}` |
| Secret storage audit trail | Azure Key Vault / Azure DevOps library audit logs | `{audit-log-reference}` |
| Deployment run history | Azure DevOps pipeline run | `{pipeline-run-reference}` |
| Periodic review | Review record / work item | `{review-reference}` |

---

## Optional _Config Application Log

> Use this section only when a program has a documented auditor requirement for a
> manually applied, unmanaged `_Config` solution. `_Config` is never committed to source
> control and never included in any pipeline. Log names and approvals only — never values.

| Date | Environment | Applied By | Changes | Approval / Change Reference | Notes |
|---|---|---|---|---|---|
| `YYYY-MM-DD` | Test | `{name}` | Initial environment variable names only | `{reference}` | |
| `YYYY-MM-DD` | Prod | `{name}` | Initial environment variable names only | `{reference}` | |

---

## Team / Owner Group Provisioning Log

> Owner Teams are environment data (not solution components). Track their creation here.

| Environment | Team Name | Type | Security Role | Created By | Date |
|---|---|---|---|---|---|
| All | `{ProjectCode} Administrators` | Owner | `{ProjectCode} - Administrator` | | `YYYY-MM-DD` |
| All | `{ProjectCode} Contributors` | Owner | `{ProjectCode} - Contributor` | | `YYYY-MM-DD` |
| All | `{ProjectCode} Readers` | Owner | `{ProjectCode} - Read Only` | | `YYYY-MM-DD` |
| All | `{ProjectCode} Support` | Owner | `{ProjectCode} - Support` | | `YYYY-MM-DD` |

---

## Change Log

| Date | Changed By | Change |
|---|---|---|
| `YYYY-MM-DD` | | Initial register created |
