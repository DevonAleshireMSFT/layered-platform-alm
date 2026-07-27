# Project Schema Inventory

> AI context file. Maintain this as the authoritative table and column reference.
> AI tools use this to suggest correct logical names in flows, expressions, and connectors.
>
> **How to update:** After each `_Core` export/unpack cycle, review the `Entities/` folder
> for new or changed tables and columns, then update this file.
>
> Alternatively, generate this file from the unpacked solution XML:
>   `pac solution unpack` → inspect `solutions/{ProjectCode}_Core/src/Entities/` XML files.

---

## Tables

| Display Name | Logical Name | Primary Name Column | Primary Key | Layer |
|---|---|---|---|---|
| *(add tables here)* | `{prefix}_{name}` | `{prefix}_{name}name` | `{prefix}_{name}id` | `_Core` |

---

## Columns by Table

> List columns for each table. Include logical name, type, and any lookup targets.

### `{prefix}_{tablename}` — {Display Name}

| Display Name | Logical Name | Type | Need Level | Notes |
|---|---|---|---|---|
| *(add columns)* | `{prefix}_{columnname}` | Text / Lookup / Choice / DateTime / etc. | Yes/No | |

---

## Global Option Sets (Shared Choices)

| Display Name | Logical Name | Values |
|---|---|---|
| *(add global option sets)* | `{prefix}_{name}` | Value1, Value2, Value3 |

---

## Relationships

| Parent Table | Child Table | Relationship Name | Type | Lookup Column on Child |
|---|---|---|---|---|
| *(add relationships)* | | `{prefix}_{parent}_{child}_{type}` | 1:N / N:N | `{prefix}_{parent}id` |

---

## Environment Variable Definitions

> These are schema (`_Core` layer). Environment variable values are deployment-controlled Config Gate data and are never committed.
> Do not track current values in this file or in any committed solution artifact.

| Display Name | Schema Name | Type | Default Value | Used By |
|---|---|---|---|---|
| *(add env var definitions)* | `{prefix}_{name}` | String / JSON / Number / Boolean | | `_Automation` flows |

---

## Generation Commands

To extract table/column information from the unpacked solution:

```powershell
# List all entity (table) XML files
Get-ChildItem -Path "solutions/{ProjectCode}_Core/src/Entities" -Filter "*.xml" |
  Select-Object -ExpandProperty BaseName

# View a specific entity definition
Get-Content "solutions/{ProjectCode}_Core/src/Entities/{TableName}/{TableName}.xml" |
  Select-String -Pattern "LocalizedName|LogicalName|AttributeType"
```

Or use PAC CLI to inspect:
```bash
pac solution list --environment https://yourorg-dev.crm.microsoftdynamics.us
```
