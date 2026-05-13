---
layout: default
title: Onboarding Checklist
nav_order: 3
description: "Step-by-step checklist for new developer onboarding, new project setup, and pre-pipeline-run validation."
permalink: /onboarding/
---

# LP-ALM Onboarding Checklist

> Use this checklist when onboarding a new team member, setting up a new project environment,
> or validating that a project is fully LP-ALM compliant before the first pipeline run.

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

### Phase 1: Publisher and Solutions (in Dev environment)

- [ ] Create publisher in Dev:
  - Display Name: `{Project Name} Platform`
  - Unique Name: `{projectname}platform`
  - Prefix: `{prefix}` (2–5 lowercase alpha chars)
  - Note the prefix — it is permanent after first schema deployment

- [ ] Create five empty solutions in Dev, all linked to the new publisher:
  - [ ] `{ProjectCode}_Security`
  - [ ] `{ProjectCode}_Core`
  - [ ] `{ProjectCode}_Config`
  - [ ] `{ProjectCode}_Automation`
  - [ ] `{ProjectCode}_UI`

### Phase 2: Repository Setup

- [ ] Clone the LP-ALM reference repository (or fork `layered-platform-alm`)
- [ ] Update `.ai/context.md` with project code, prefix, environment URLs
- [ ] Update `.ai/conventions.md` with actual prefix and solution names
- [ ] Update `pipelines/*.yml` — replace `SYSTRK` with actual `{ProjectCode}`
- [ ] Update `pipelines/*.yml` — replace `SYSTRK-Common`, `SYSTRK-Test`, `SYSTRK-Prod` with actual variable group names
- [ ] Update `docs/environment-register-template.md` with actual environment details
- [ ] Commit initial repository configuration

### Phase 3: Service Principal Setup

**GCC High:**
- [ ] Create App Registration in Azure Government (`portal.azure.us`):
  - Name: `{ProjectCode}-Pipeline-SP`
  - Supported account types: Single tenant
  - Generate client secret (store in Azure Key Vault, not here)
- [ ] Create Application User in each Power Platform environment:
  ```
  Power Platform Admin Center → Environments → {env} → Settings → Users → Application Users → New
  ```
- [ ] Assign System Administrator role to the Application User in each environment
- [ ] Document the App ID in `docs/environment-register-template.md` (no secrets in this file)

### Phase 4: Azure DevOps Variable Groups

- [ ] Create variable group `{ProjectCode}-Common`:
  - `ProjectCode` = `{ProjectCode}`
  - `PublisherPrefix` = `{prefix}`
  - `SolutionVersion.Major` = `1`
  - `SolutionVersion.Minor` = `0`

- [ ] Create variable group `{ProjectCode}-Test`:
  - `Test.EnvironmentUrl` = `https://{org}-test.crm.microsoftdynamics.us`
  - `Test.ApplicationId` = `{app-id}`
  - `Test.TenantId` = `{tenant-id}`
  - `Test.ClientSecret` = `{secret}` ← **Mark as secret**

- [ ] Create variable group `{ProjectCode}-Prod`:
  - `Prod.EnvironmentUrl` = `https://{org}.crm.microsoftdynamics.us`
  - `Prod.ApplicationId` = `{app-id}`
  - `Prod.TenantId` = `{tenant-id}`
  - `Prod.ClientSecret` = `{secret}` ← **Mark as secret**

- [ ] Grant pipeline permission to each variable group in Azure DevOps

### Phase 5: Azure DevOps Pipeline Setup

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
  - `{ProjectCode} - Deploy UI`
- [ ] Create Azure DevOps Environment `{ProjectCode}-Test` with no approval gates
- [ ] Create Azure DevOps Environment `{ProjectCode}-Prod` with manual approval gate (require one approver)

### Phase 6: Branch Protection

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
- [ ] `{ProjectCode}_Automation` exported, unpacked, and committed to source control
- [ ] `{ProjectCode}_UI` exported, unpacked, and committed to source control
- [ ] `{ProjectCode}_Config` **NOT** in source control (verify with `git status`)
- [ ] PR validation pipeline passes on current branch (all four layers pack successfully)
- [ ] Schema contamination check passes (`_UI` has no `Entities/` content)
- [ ] Config exclusion check passes (`_Config` directory not present in source)

### Target Environment Readiness

- [ ] Service principal Application User exists in target environment
- [ ] System Administrator role assigned to Application User in target environment
- [ ] `{ProjectCode}_Config` manually imported to target environment
- [ ] All environment variable values confirmed in target environment
- [ ] Connection references in target environment bound to service account connections (not personal)
- [ ] Service account connections verified (not using expiring personal credentials)
- [ ] No personal email addresses in any connection

### Pipeline Readiness

- [ ] Azure DevOps variable group `{ProjectCode}-{TargetEnv}` populated (including secrets)
- [ ] Pipeline service connection configured and connection test passes
- [ ] Environment URL in variable group matches actual target URL (`.crm.microsoftdynamics.us` for GCC High)
- [ ] Correct `--cloud UsGovHigh` flag confirmed in pipeline auth steps

### Solution Version Check

- [ ] `SolutionVersion.Major` correct for this release in variable group
- [ ] `SolutionVersion.Minor` correct for this release in variable group
- [ ] Build ID will be appended automatically — no manual action needed for the build number

---

## Part 4: _Config Management Protocol

> `_Config` never enters source control or pipelines. This protocol documents how to manage it.

### Applying _Config to a New Environment

1. Export `_Config` from the reference environment (Dev):
   ```bash
   pac solution export --name {ProjectCode}_Config --path ./{ProjectCode}_Config_$(date +%Y%m%d).zip --managed false --overwrite true
   ```

2. **Do not unpack or commit the ZIP.**

3. Transfer the ZIP to a secure location (encrypted file share or shared drive — not the repo).

4. Modify environment variable values for the target environment (open ZIP, edit XML, re-ZIP — or use Power Platform import with overwrite to set values interactively).

5. Import to target environment:
   ```bash
   pac solution import --path ./{ProjectCode}_Config_{date}.zip --force-overwrite true --publish-changes true
   ```

6. Verify environment variable values in the target environment via the maker portal.

7. Log the application in `docs/environment-register-template.md` (date, who applied, what changed).

8. Delete the local ZIP from your workstation when done.

### _Config Change Tracking

Since `_Config` is not in source control, changes are tracked in `docs/environment-register-template.md` under the `_Config Application Log` section. Every `_Config` application must be logged with:
- Date
- Environment
- Who applied it
- Summary of what changed (value names, not values)
