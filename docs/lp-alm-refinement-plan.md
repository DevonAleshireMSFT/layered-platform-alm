---
layout: default
title: LP-ALM Refinement Plan
nav_order: 8
description: "Plan for evolving LP-ALM from fixed layers to mandatory invariants plus optional solution layers for government Power Platform delivery."
permalink: /lp-alm-refinement-plan/
---

# LP-ALM Refinement Plan

This plan synthesizes the team's review of external recommendations into an adoptable foundation for government Power Platform solution decomposition. It is not intended to become a perfect prescription for every program; it defines mandatory invariants, clear decision points, and right-sized optional layers that project teams can tailor without weakening LP-ALM's security, configuration, or managed-deployment controls.

---

## 1. Executive Summary

LP-ALM should evolve from **five fixed layers** to **ordered mandatory invariants plus optional solution layers**. The core sequence remains strict: `_Security` deploys first, `_Core` owns schema, configuration values never enter source control, upper environments receive managed solutions only, and `_UI` remains schema-free. What changes is the assumption that every project must instantiate every possible solution, even when a layer would be empty or premature.

This is the best way to break down solutions in government spaces because it preserves the controls auditors care about while reducing adoption friction for smaller programs. Government delivery needs evidence, least privilege, separation of duties, controlled configuration, and repeatable managed promotion; it does not need empty layers created only to satisfy a diagram. The refined model makes LP-ALM easier to adopt as a foundation while keeping its non-negotiable compliance posture intact.

---

## 2. Recommended Changes

| Change | Current | Proposed | Verdict | Why | Government note |
|---|---|---|---|---|---|
| Stop mandating a dedicated `_Config` solution; prefer a deployment configuration gate | `_Config` is a manual, uncommitted solution layer between `_Core` and `_Automation` that carries environment variable values. | Default to the Config Gate: environment variable **definitions** live in `_Core`; values and connection bindings are deployment-controlled data supplied through secret-backed Azure DevOps variables / Key Vault and an ephemeral `pac solution import --settings-file` file that is generated, used, deleted, and never published as an artifact. Allow a recognized high-control alternative: a dedicated **unmanaged** `_Config` solution that is never committed and is manually applied when auditors require a tangible solution-artifact evidence trail. | 🟡 Adopt with conditions | Dataverse already separates environment variable definitions from values. LP-ALM should stop mandating `_Config` for every project, but it should not forbid the pattern. Governed defaults, opt out with justification. | The evidence gap must be closed either way: the environment configuration register becomes the authoritative non-secret record for CM-2, CM-3, and CM-6. It stores metadata only: logical name, environment, owner, required/optional status, secret classification, source variable name, and last-reviewed date. |
| Introduce tiered architectures | LP-ALM describes a five-layer baseline: `_Security`, `_Core`, `_Config`, `_Automation`, `_UI`. | Define tiers: **Minimum** = Security + Core + UI; **Standard** = Minimum + Automation; **Enterprise** = Standard + Integration + multiple UIs as warranted. | ✅ Adopt | This makes the methodology usable for small and large government programs without forcing empty solutions. | "Minimum" means fewer components, not weaker controls. Security first, schema in Core, schema-free UI, managed Test/Prod, zero committed values, and service-account / non-personal bindings still apply. |
| Split web resources by dependency direction | `_UI` includes app-facing web resources; `_Core` owns forms and schema-adjacent behavior. | Split by **physical files** and dependency direction. Shared stable libraries and data-integrity behavior needed by Core forms live in `_Core`; UX-only web resources live in `_UI`. `_Core` forms must never depend on `_UI` web resources. | ✅ Adopt | Intent alone is not enough; Dataverse dependencies are created by actual file references. This rule prevents reversed layer dependencies. | Client-side JavaScript is UX assistance, not a security or integrity boundary. True integrity must be enforced through required fields, relationships, business rules, plugins, server-side logic, and security roles. |
| Create `_Integration` only when warranted | Appendix A allows `_Integration` for large, shared, or separately released integrations. | Keep `_Integration` optional and trigger it when integrations are numerous, shared, separately owned, independently released, or cross governance / security boundaries. | 🟡 Adopt with conditions | Starting without `_Integration` is safe for simple projects, but refactor cost rises once connectors and connection references become shared platform assets. Split before they are widely consumed. | Government triggers include cross-boundary data exchange, CUI movement, external ATO dependency, independently governed service connections, or separately authorized integration services. |
| Recommend Operations/Admin UI split by criteria | Current guidance allows split UI solutions when ownership, cadence, targets, or blast radius differ. | Recommend `{ProjectCode}_UI_Operations` and `{ProjectCode}_UI_Admin` by default when admin capability exists, but keep the split criteria-driven. | ✅ Adopt | Admin functions commonly need distinct privileges, review gates, and release controls. | Supports separation of duties, least privilege, and audit isolation without requiring separate data schemas. Both UIs depend on `_Security` and `_Core`; neither may contain schema. |
| Treat Reporting and Test Data as optional lifecycle layers | Reporting and test data are not first-class optional layers in the primary model. | Add optional Reporting and Test Data rows to the decision model and dependency matrix when the artifacts are substantial and have an independent lifecycle. | ✅ Adopt | Some programs need auditable reports or repeatable test datasets, but many do not. | Test data must never contain real sensitive production data unless explicitly authorized and documented. Reporting may require row-level access through `_Security`. |

---

## 3. Layer Decision Model

Use this decision model as the centerpiece for solution decomposition:

1. **Always create `_Security`.** It contains roles, field security profiles, protected data access structures, and anything that must enter Test/Prod before schema.
2. **Always create `_Core`.** It contains all schema: tables, columns, relationships, views, forms, keys, choices, charts, and environment variable definitions.
3. **Default to the Config Gate; do not mandate `_Config`.** Manage values as environment deployment data through secret-backed pipeline variables / Key Vault, the environment configuration register, and a Config Gate. Values and connection bindings are never committed to source control. A dedicated **unmanaged** `_Config` solution remains a recognized high-control alternative only when auditors require a solution-artifact evidence trail; it is never committed and is manually applied with documented justification.
4. **Create `_Automation` when automation exists.** Use it for flows, custom connectors, connection references, scheduled jobs, and data-processing logic. Do not create it for a project that genuinely has no flows, connectors, connection references, or scheduled jobs.
5. **Create `_UI` when user-facing artifacts exist.** Use it for model-driven apps, canvas apps, dashboards, site maps, PCF controls, custom pages, and UX web resources. `_UI` cannot contain schema.
6. **Split UI only for distinct ownership, release cadence, deployment target, persona boundary, or blast radius.** Use Operations/Admin split by default when admin capability exists, but avoid splitting merely for preference.
7. **Create `_Integration` only when integrations are shared, numerous, separately owned, independently released, or government-governed as cross-boundary services.** Split before shared connectors become hard to unwind.
8. **Create Reporting or Test Data solutions only when the artifacts are substantial and have an independent lifecycle.** Keep reporting dependencies explicit and keep test data synthetic unless production data use is authorized.

### Tier Selection Requires Justification

Tier selection must be recorded as an ADR-style decision before implementation. The record should state the selected tier, the facts that justify it, rejected alternatives, and the evidence location for future audit review.

- **Minimum** is allowed only when there are no external integrations, no cross-boundary or CUI data movement, and no privileged admin UI.
- **Standard** applies when automation exists but integrations are not shared, cross-boundary, or independently governed.
- **Enterprise** is required when CUI exchange, shared connection references, cross-system orchestration, separately governed integrations, or external ATO dependencies exist.

This prevents teams from choosing a smaller tier to dodge governance. Governed defaults remain the baseline; projects may opt out of optional layers only with documented justification.

---

## 4. Updated Dependency Matrix

| Solution / Gate | Depends on | Notes |
|---|---|---|
| `_Security` | Nothing | First deployed layer in every tier. Can deploy to an empty environment. |
| `_Core` | `_Security` | Owns all schema and environment variable definitions. |
| Config Gate | `_Security`, `_Core` | Default pattern. Not a solution. Requires environment-specific values and connection bindings to exist before `_Automation` and any dependent `_UI` activate. Values are secret-backed deployment data and never source artifacts. A manually applied, unmanaged `_Config` solution is allowed only as a documented high-control alternative; it is never committed. |
| `_Integration` (optional) | `_Security`, `_Core`; Config Gate before activation when values / bindings are required | Use when connectors, external services, service connections, or cross-boundary exchanges are shared or independently governed. |
| `_Automation` (optional) | `_Security`, `_Core`; `_Integration` when consuming shared integration components; Config Gate before activation | Contains flows, connection references, custom connectors, and scheduled jobs. |
| `_UI_Operations` or `_UI` | `_Security`, `_Core`; `_Automation` optional; Config Gate when consuming configured values / bindings | User-facing applications. Must remain schema-free. |
| `_UI_Admin` (optional) | `_Security`, `_Core`; `_Automation` optional; Config Gate when consuming configured values / bindings | Independent of `_UI_Operations`; recommended when admin capability exists and separation of duties matters. |
| `_Reporting` (optional) | `_Core`; `_Security` when row-level access or governed distribution is required | Use for substantial reporting artifacts with a distinct lifecycle. |
| `_TestData` (optional) | `_Security`, `_Core`; `_Automation` optional | Use for synthetic test datasets and validation assets. Never include real sensitive production data unless authorized. |

---

## 5. Non-Negotiable Government Floor

These controls apply in every tier, including Minimum:

- `_Security` is always its own first-deployed layer in every environment.
- `_Core` is the only schema layer.
- `_UI` cannot contain schema: no tables, columns, relationships, or structural data definitions.
- Test and Prod receive managed solutions only; Dev receives unmanaged.
- Environment-specific values, secrets, tenant identifiers, connection bindings, and raw configuration values are never committed to source control.
- Configuration values are deployment-controlled artifacts backed by approved secret storage and documented by a non-secret environment configuration register.
- A dedicated unmanaged `_Config` solution may be used as a high-control auditor evidence pattern, but it is optional, manually applied, justified in writing, and never committed to source control.
- Connection references use service accounts or another approved non-personal credential model in upper environments; personal credential bindings are not acceptable for Test or Prod.
- GCC High environment URLs use `.crm.microsoftdynamics.us`, and PAC CLI authentication for GCC High uses `--cloud UsGovHigh`.
- The pipeline service principal requires the Dataverse built-in System Administrator role to deploy security roles because of the `prvWriteRole` platform requirement.
- Append and Append To privileges must be explicitly set in every security role for every relationship a role traverses.
- Dataverse Owner Teams use "Direct User (Basic) access level and Team privileges," not Business Unit level.
- Automation may be omitted only when the application genuinely has no flows, connectors, connection references, scheduled jobs, or automation runtime assets.
- Test data must never contain real sensitive production data unless explicitly authorized, documented, and controlled.

---

## 6. Implementation Roadmap

1. **[methodology] Update `LP-ALM.md` Executive Summary and Layer Definitions — Owner: Link + Morpheus**  
   Reframe LP-ALM as mandatory invariants plus optional layers. Replace "five fixed layers" language with tiered architecture language while preserving the ordered dependency contract.

2. **[methodology] Rewrite `LP-ALM.md` Section 2.3 from mandatory `_Config` layer to Config Gate default — Owner: Link + Tank + Niobe**  
   State that environment variable definitions belong in `_Core`; values and connection bindings are deployment-controlled data. Describe the Config Gate, the environment configuration register, the zero-secrets rule, and the optional unmanaged `_Config` pattern for auditors who require solution-artifact evidence.

3. **[methodology] Update `LP-ALM.md` Sections 2.4 and 2.5 for optional Automation and schema-free UI — Owner: Link + Tank**  
   Make `_Automation` conditional on actual automation assets. Strengthen `_UI` dependency rules, including web-resource placement by physical file and dependency direction.

4. **[methodology] Expand `LP-ALM.md` Section 2.6 and Appendix A — Owner: Link + Morpheus + Tank**  
   Add Minimum / Standard / Enterprise tiers; criteria for UI Operations/Admin split; criteria for `_Integration`; and optional Reporting / Test Data lifecycle guidance.

5. **[methodology] Update `LP-ALM.md` Section 3.4 NIST 800-53 mapping and ATO language — Owner: Link + Niobe**  
   Revise CM-2, CM-3, and CM-6 language so configuration values are described as deployment-controlled artifacts evidenced by the environment configuration register by default, with unmanaged `_Config` recognized only as a justified high-control evidence alternative.

6. **[ai-context] Update `.ai\context.md` and `.ai\layers.md` — Owner: Link**  
   Replace the fixed five-layer table with mandatory invariants, tiered layers, and the Layer Decision Model. Keep placeholders `{ProjectCode}`, `{prefix}`, and `{org}` intact.

7. **[ai-context] Review `.ai\conventions.md` and `.ai\schema.md` for drift — Owner: Link + Tank**  
   Ensure naming examples and schema guidance still reinforce `{ProjectCode}_{Layer}`, schema-in-Core, and environment variable definitions vs. values.

8. **[docs] Update `docs\component-placement-decision-tree.md` — Owner: Link + Tank**  
   Replace mandatory `_Config` placement with Config Gate default language and the optional unmanaged `_Config` evidence pattern. Add web-resource split rules and optional Integration / Reporting / Test Data decisions.

9. **[docs] Update `docs\environment-register-template.md` — Owner: Link + Niobe**  
   Make the register the authoritative non-secret configuration evidence record. Add columns for logical name, environment, owner, required/optional, secret classification, source variable name, approval / change reference, and last-reviewed date.

10. **[docs] Update `docs\onboarding-checklist.md` and `docs\enterprise-strategy-gcc-high.md` — Owner: Link + Niobe**  
    Add tier selection, Config Gate validation, GCC High URL validation, non-personal connection binding validation, and evidence expectations for government delivery.

11. **[docs] Update `docs\security-role-matrix-template.md` — Owner: Link + Niobe + Tank**  
    Ensure Append and Append To privilege review remains explicit and owner-team access guidance remains aligned to "Direct User (Basic) access level and Team privileges."

12. **[pipelines] Update `pipelines\deploy-all.yml` orchestration — Owner: Dozer + Link**  
    Replace the manual `_Config` step with a Config Gate stage that validates required values / bindings before deploying `_Automation`, `_Integration`, or dependent `_UI` solutions.

13. **[pipelines] Update layer deployment templates — Owner: Dozer**  
    Add support for ephemeral settings-file generation from approved Azure DevOps variable groups / Key Vault references. The file must be generated in the pipeline workspace, used by `pac solution import --settings-file`, deleted after use, and never published as an artifact.

14. **[pipelines] Update `pipelines\pr-validation.yml` — Owner: Dozer + Tank**  
    Add validation to detect forbidden committed environment variable value files, committed `_Config` solution artifacts, schema inside UI solutions, and reversed `_Core` to `_UI` web-resource dependencies where detectable.

15. **[docs] Add migration notes for existing adopters — Owner: Link + Morpheus**  
    Explain how teams already using `_Config` can move to the Config Gate without weakening controls: keep definitions in `_Core`, remove value artifacts from source, populate secret-backed deployment values, and update the environment register. Also explain when keeping a never-committed unmanaged `_Config` solution is acceptable as an auditor-driven evidence pattern.

---

## 8. Risks & Mitigations (v1 foundation)

This refinement is intentionally a v1 foundation. It improves the model while acknowledging the controls that must be made explicit before broader adoption.

### Must Mitigate Now

- Secret-leakage controls for generated settings files, including where they are written, when they are deleted, and confirmation that they are never published as artifacts.
- Pipeline log masking guidance for values sourced from Azure DevOps variable groups, Key Vault, service connections, or generated settings files.
- A Config Gate validation checklist covering required environment variables, secret classifications, connection bindings, service account / non-personal credential ownership, and pre-activation readiness.
- Explicit tier decision criteria and ADR-style tier justification so Minimum cannot be selected to avoid governance.
- A documented auditor evidence model showing how configuration governance is proven without a `_Config` solution: environment register metadata + Key Vault / Azure DevOps audit logs + approval records + deployment run history.

### Accept for v1 (Conscious Risk)

- Optional-layer taxonomy may create some cross-project variance while teams learn how to apply the model.
- UI Operations/Admin split criteria may need refinement after real project adoption shows where separation creates value versus unnecessary deployment overhead.
- Integration thresholds may evolve as programs discover when connectors, connection references, and cross-system orchestration become shared platform assets.

---

## 9. Why This Is the Best Foundation for Government

This refinement gives government programs the control structure they need without forcing every project into the same physical solution shape. The invariant rules remain strict: security precedes schema, schema lives only in Core, UI cannot carry schema, configuration values never enter source control, Test and Prod stay managed, and non-personal credentials are required for upper-environment bindings. Those are the controls that support auditability, least privilege, separation of duties, and change management.

At the same time, optional layers make LP-ALM more adoptable. A small application can start with Security, Core, and UI while still meeting the government floor. A larger enterprise program can add Automation, Integration, Admin UI, Reporting, and Test Data when ownership, release cadence, boundary crossing, or evidence needs justify them. That makes LP-ALM a practical foundation: strong enough for GCC High and FedRAMP-oriented delivery, flexible enough for real project variation, and clear enough for teams to apply without waiting for a perfect prescription.
