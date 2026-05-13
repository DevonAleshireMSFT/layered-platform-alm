# Environment Register

> **What this is:** The authoritative reference for all Power Platform environments in this project.
>
> **What this is NOT:** A secrets store. No client secrets, passwords, or API keys are recorded here.
> Secrets live in Azure Key Vault and Azure DevOps variable groups only.
>
> **Who maintains this:** The platform architect. Update when environments are created, decommissioned,
> or their properties change.

---

## Environment Summary

| Environment | Type | Purpose | Managed Solutions? | Pipeline? |
|---|---|---|---|---|
| Dev | Sandbox / Unmanaged | Active development | ❌ No | ❌ No |
| Test | Managed | Integration testing and validation | ✅ Yes | ✅ Yes |
| Prod | Managed | Production | ✅ Yes | ✅ Yes |

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
| **Service Principal (App ID)** | `{app-id-dev}` — stored in ADO variable group, not here |
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
| **Service Principal (App ID)** | `{app-id-test}` — stored in ADO variable group `{ProjectCode}-Test` |
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
| **Service Principal (App ID)** | `{app-id-prod}` — stored in ADO variable group `{ProjectCode}-Prod` |
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

| Environment | App Name | App ID | Tenant | Role in Environment | Created By | Expires |
|---|---|---|---|---|---|---|
| All | `{ProjectCode}-Pipeline-SP` | `{app-id}` | `{tenant-id}` | System Administrator | | `YYYY-MM-DD` |

> **GCC High Note:** App registrations for GCC High environments must be created in the
> Azure Government tenant (`portal.azure.us`), not the commercial Azure portal.

---

## _Config Application Log

> Track when `_Config` was manually applied to each environment.
> This log is the alternative to source control for `_Config` change tracking.

| Date | Environment | Applied By | Changes | Notes |
|---|---|---|---|---|
| `YYYY-MM-DD` | Test | `{name}` | Initial environment variable values | |
| `YYYY-MM-DD` | Prod | `{name}` | Initial environment variable values | |

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
