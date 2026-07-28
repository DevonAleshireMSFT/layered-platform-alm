---
layout: default
title: Onboarding Checklist
nav_order: 3
description: "Step-by-step checklist for new developer onboarding, new project setup, and pre-pipeline-run validation."
permalink: /onboarding/
---

# LP-ALM Onboarding Checklist

> Use this checklist when onboarding a new team member, setting up a new project environment,
> or validating that a project follows the LP-ALM secure baseline before the first pipeline run.

---

## Part 1: New Developer Onboarding

### Tools Setup

- [ ] Install [PAC CLI](https://learn.microsoft.com/en-us/power-platform/developer/cli/introduction)
  ```bash
  # Install via npm
  npm install -g @microsoft/powerplatform-vscode

  # Or install via .NET tool
  dotnet tool install --global Microsoft.PowerApps.CLI.Tool
  ```

- [ ] Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [ ] Install [Git](https://git-scm.com/)
- [ ] Request access to the Azure DevOps project and repository
- [ ] Clone the repository:
  ```bash
  git clone https://dev.azure.com/{org}/{project}/_git/{repo}
  cd {repo}
  ```

### Environment Access

- [ ] Request access to the Dev Power Platform environment
- [ ] Confirm you can sign in to `https://gcc.admin.powerplatform.microsoft.us`
- [ ] Confirm your user account has at least Contributor-level access in the Dev environment
- [ ] Verify your user account has the `{ProjectCode} - Contributor` security role (or higher) in Dev

### Understanding the Project Structure

- [ ] Read [.ai/context.md](.ai/context.md) — project identity, environment list, rules
- [ ] Read [.ai/layers.md](.ai/layers.md) — quick reference for where components go
- [ ] Read [.ai/conventions.md](.ai/conventions.md) — naming conventions
- [ ] Read [LP-ALM.md](LP-ALM.md) — full methodology (Section 2 at minimum)
- [ ] Review [docs/security-role-matrix-template.md](docs/security-role-matrix-template.md)
- [ ] Review [docs/component-placement-decision-tree.md](docs/component-placement-decision-tree.md)
- [ ] Confirm the secure ALM baseline:
  - `_Security` deploys first
  - `_Core` owns all schema
  - UI solutions contain no tables, columns, relationships, or other schema
  - Test and Prod receive managed solutions only
  - Configuration values, connection bindings, and secrets are never committed

### First Contribution

- [ ] Check out a feature branch:
  ```bash
  git checkout -b feature/my-first-change
  ```
- [ ] Make a change in Dev (e.g., add a view to `_Core` solution)
- [ ] Export and unpack the affected layer:
  ```bash
  pac solution export --name {ProjectCode}_Core --path ./exports/{ProjectCode}_Core.zip --managed false --overwrite true
  pac solution unpack --zipfile ./exports/{ProjectCode}_Core.zip --folder ./solutions/{ProjectCode}_Core/src --packagetype Unmanaged --allowDelete true --allowWrite true --clobber true
  ```
- [ ] Review `git diff` — verify only expected files changed
- [ ] Commit and push
- [ ] Open a PR to the `test` branch and verify the validation pipeline passes

---

## Part 2: New Project Setup Checklist

### Phase 1: Tier Selection, Publisher, and Solutions (in Dev environment)

- [ ] Select the project tier and record an ADR-style justification:
  - [ ] **Minimum** — `{ProjectCode}_Security`, `{ProjectCode}_Core`, `{ProjectCode}_UI_Operations`
  - [ ] **Standard** — Minimum + `{ProjectCode}_Automation`
  - [ ] **Enterprise** — Standard + warranted optional layers such as `{ProjectCode}_Integration`, `{ProjectCode}_UI_Admin`, reporting, or test data
- [ ] ADR includes selected tier, facts supporting the tier, rejected alternatives, and evidence location.
- [ ] Confirm **Minimum** is used only when there are no external integrations, no cross-boundary or CUI data movement, and no privileged admin UI.
- [ ] Confirm **Enterprise** is selected when CUI exchange, shared connection references, cross-system orchestration, separately governed integrations, or external ATO dependencies warrant it.

- [ ] Create publisher in Dev:
  - Display Name: `{Project Name} Platform`
  - Unique Name: `{projectname}platform`
  - Prefix: `{prefix}` (2–5 lowercase alpha chars)
  - Note the prefix — it is permanent after first schema deployment

- [ ] Create tier-appropriate empty solutions in Dev, all linked to the new publisher:
  - [ ] `{ProjectCode}_Security`
  - [ ] `{ProjectCode}_Core`
  - [ ] `{ProjectCode}_UI_Operations`
  - [ ] `{ProjectCode}_Automation` *(Standard / Enterprise when automation exists)*
  - [ ] `{ProjectCode}_Integration` *(Enterprise when warranted)*
  - [ ] `{ProjectCode}_UI_Admin` *(when privileged admin capability exists)*

> `_Config` is not a mandated solution. Use the Config Gate by default. A manually
> applied unmanaged `_Config` solution is allowed only with documented auditor-driven
> justification, and it is never committed or included in a pipeline.

### Phase 2: Repository Setup

- [ ] Clone the LP-ALM reference repository (or fork `layered-platform-alm`)
- [ ] Update `.ai/context.md` with project code, prefix, environment URLs
- [ ] Update `.ai/conventions.md` with actual prefix and solution names
- [ ] Update `pipelines/*.yml` — replace `SYSTRK` with actual `{ProjectCode}`
- [ ] Update `pipelines/*.yml` — replace `SYSTRK-Common`, `SYSTRK-Test`, `SYSTRK-Prod` with actual variable group names
- [ ] Update `docs/environment-register-template.md` with actual environment details
- [ ] Populate the Configuration Evidence Register with metadata only: logical name, environment, owner, required/optional status, secret classification, source variable name / Key Vault reference, approval/change reference, and last-reviewed date
- [ ] Commit initial repository configuration

### Phase 3: Service Principal Setup

**GCC High example (adapt portal, cloud, and authority values for the target environment):**
- [ ] Create App Registration in Azure Government (`portal.azure.us`):
  - Name: `{ProjectCode}-Pipeline-SP`
  - Supported account types: Single tenant
  - Generate client secret (store in Azure Key Vault, not here)
- [ ] Create Application User in each Power Platform environment:
  ```
  Power Platform Admin Center → Environments → {env} → Settings → Users → Application Users → New
  ```
- [ ] Assign System Administrator role to the Application User in each environment
- [ ] Confirm pipeline authentication uses service-principal auth with the target-cloud flag (for GCC High, `--cloud UsGovHigh`)
- [ ] Document App ID / tenant references in `docs/environment-register-template.md` as metadata only (no secrets or raw values in this file)

### Phase 4: Connection Reference Identity Planning

- [ ] Use dedicated service account connections as the recommended default for connection references.
- [ ] If dedicated service accounts are not available, document the approved fallback before deployment:
  - [ ] least-privilege delegated identity selected for the connector
  - [ ] owning team or steward recorded, with backup ownership
  - [ ] rotation or periodic review cadence recorded
  - [ ] approval/change reference captured in the Environment Register
- [ ] Confirm no raw credentials, connection strings, or secret values are recorded in docs or source control.
- [ ] Update the Connection Reference Identity Register in `docs/environment-register-template.md` with the default or fallback evidence.

### Phase 5: Azure DevOps Variable Groups

- [ ] Create variable group `{ProjectCode}-Common`:
  - `ProjectCode` = `{ProjectCode}`
  - `PublisherPrefix` = `{prefix}`
  - `SolutionVersion.Major` = `1`
  - `SolutionVersion.Minor` = `0`

- [ ] Create variable group `{ProjectCode}-Test`:
  - `Test.EnvironmentUrl` = `https://{org}-test.crm.microsoftdynamics.us`
  - `Test.ApplicationId` = ADO variable or Key Vault reference name only
  - `Test.TenantId` = ADO variable or Key Vault reference name only
  - `Test.ClientSecret` = Key Vault-backed or secret variable name only — **mark as secret**

- [ ] Create variable group `{ProjectCode}-Prod`:
  - `Prod.EnvironmentUrl` = `https://{org}.crm.microsoftdynamics.us`
  - `Prod.ApplicationId` = ADO variable or Key Vault reference name only
  - `Prod.TenantId` = ADO variable or Key Vault reference name only
  - `Prod.ClientSecret` = Key Vault-backed or secret variable name only — **mark as secret**

- [ ] Grant pipeline permission to each variable group in Azure DevOps
- [ ] Confirm each variable group entry is reflected in the Configuration Evidence Register by source variable name / Key Vault reference only, not value

### Phase 6: Azure DevOps Pipeline Setup

- [ ] Create pipeline from `pipelines/pr-validation.yml`
  - Name: `{ProjectCode} - PR Validation`
  - Trigger: PR to `test` and `main`
- [ ] Create pipeline from `pipelines/deploy-all.yml`
  - Name: `{ProjectCode} - Deploy All Layers`
  - Trigger: Push to `main`
- [ ] (Optional) Create individual layer pipelines for hotfix use:
  - `{ProjectCode} - Deploy Security`
  - `{ProjectCode} - Deploy Core`
  - `{ProjectCode} - Deploy Automation`
  - `{ProjectCode} - Deploy Operations UI`
  - `{ProjectCode} - Deploy Admin UI` *(when `{ProjectCode}_UI_Admin` exists)*
- [ ] Create Azure DevOps Environment `{ProjectCode}-Test` with no approval gates
- [ ] Create Azure DevOps Environment `{ProjectCode}-Prod` with manual approval gate (require one approver)

### Phase 7: Branch Protection

- [ ] Protect `main` branch:
  - Require PR review (minimum 1 reviewer)
  - Require build validation (PR validation pipeline must pass)
  - Prevent direct push
- [ ] Protect `test` branch:
  - Require PR review (minimum 1 reviewer)
  - Require build validation (PR validation pipeline must pass)

---

## Part 3: Pre-Pipeline-Run Validation

Complete this checklist before running the deploy pipeline to any environment for the first time, or after a major change.

### Solution Readiness

- [ ] `{ProjectCode}_Security` exported, unpacked, and committed to source control
- [ ] `{ProjectCode}_Core` exported, unpacked, and committed to source control
- [ ] `{ProjectCode}_Automation` exported, unpacked, and committed to source control when automation exists
- [ ] `{ProjectCode}_Integration` exported, unpacked, and committed to source control when the selected tier includes it
- [ ] `{ProjectCode}_UI_Operations` exported, unpacked, and committed to source control when user-facing artifacts exist
- [ ] `{ProjectCode}_UI_Admin` exported, unpacked, and committed to source control when privileged admin UI exists
- [ ] `_Config` **NOT** in source control (verify with `git status`)
- [ ] PR validation pipeline passes on current branch (all required tier layers pack successfully)
- [ ] Schema contamination check passes (`_UI_Operations` and `_UI_Admin` have no `Entities/` content)
- [ ] Config exclusion check passes (`_Config` directory not present in source)

### Target Environment Readiness

- [ ] Service principal Application User exists in target environment
- [ ] System Administrator role assigned to Application User in target environment
- [ ] Target environment URL matches the approved cloud domain (for GCC High, `.crm.microsoftdynamics.us`)
- [ ] Test and Prod deployment package type is managed only; Dev deployment package type is unmanaged
- [ ] Config Gate confirms all required environment variables have approved source variable names / Key Vault references
- [ ] Config Gate confirms no raw values, secrets, tenant secrets, connection strings, or generated settings files are committed or published as artifacts
- [ ] Configuration Evidence Register has current owner, required/optional, secret classification, approval/change reference, and last-reviewed date for each required value
- [ ] Connection references in target environment use dedicated service account connections by default.
- [ ] If service accounts are unavailable, each connection reference has an approved fallback: least-privilege delegated identity, documented owner/steward, backup ownership, rotation or review cadence, and Environment Register evidence.
- [ ] Fallback identities are verified as controlled exceptions and are not undocumented personal credentials.
- [ ] No personal email addresses appear in connection binding evidence; use owning team, role, or approved delegated identity references instead.
- [ ] If an unmanaged `_Config` solution is used as an auditor-driven exception, its manual application is justified and logged in the Optional `_Config` Application Log with names and approvals only

### Pipeline Readiness

- [ ] Azure DevOps variable group `{ProjectCode}-{TargetEnv}` populated with approved variables and secret-backed references
- [ ] Pipeline service connection configured and connection test passes
- [ ] Environment URL in variable group matches the actual target URL (`.crm.microsoftdynamics.us` for GCC High examples)
- [ ] Correct cloud flag confirmed in pipeline auth steps (`--cloud UsGovHigh` for GCC High examples)
- [ ] Generated settings file, if used by the Config Gate, is ephemeral, deleted after use, and never published as an artifact

### Solution Version Check

- [ ] `SolutionVersion.Major` correct for this release in variable group
- [ ] `SolutionVersion.Minor` correct for this release in variable group
- [ ] Build ID will be appended automatically — no manual action needed for the build number

---

## Part 4: Config Gate Protocol

> Configuration values are deployment-controlled data. They never enter source control,
> pipeline artifacts, or documentation as raw values.

### Config Gate Validation

1. Confirm every required environment variable definition exists in `{ProjectCode}_Core`.
2. Confirm each required value has a source variable name or Key Vault reference in the Configuration Evidence Register.
3. Confirm secret classifications are correct and raw values are not recorded in source, docs, logs, or artifacts.
4. Confirm connection references use dedicated service account connections by default, or an approved fallback with least-privilege delegated identity, documented owner/steward, backup ownership, review/rotation cadence, and Environment Register evidence.
5. Confirm PAC authentication uses the target-cloud flag (`--cloud UsGovHigh` for GCC High examples).
6. Confirm Test and Prod receive managed solutions only.
7. Confirm the deployment run, approvals, and variable / Key Vault audit evidence are linked from the register.

### Optional _Config Exception

If auditors require a tangible solution-artifact evidence trail, a dedicated unmanaged
`_Config` solution may be manually applied. It is never committed, never unpacked into
source control, and never included in a pipeline. Record the application in
`docs/environment-register-template.md` with date, environment, who applied it, changed
logical names, approval/change reference, and no values.
