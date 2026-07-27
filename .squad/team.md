# Squad Team

> layered-platform-alm

## Coordinator

| Name | Role | Notes |
|------|------|-------|
| Neo (Squad) | Coordinator | Routes work, enforces handoffs and reviewer gates. Devon calls the coordinator "Neo". |

## Members

| Name | Role | Charter | Status |
|------|------|---------|--------|
| Morpheus | Lead / Solution Architect | .squad/agents/morpheus/charter.md | 🏗️ Active |
| Tank | Power Platform / Dataverse Engineer | .squad/agents/tank/charter.md | 🔧 Active |
| Dozer | DevOps / Pipeline Engineer | .squad/agents/dozer/charter.md | ⚙️ Active |
| Niobe | Government & Compliance Specialist | .squad/agents/niobe/charter.md | 🔒 Active |
| Link | Methodology Writer / Documentation | .squad/agents/link/charter.md | 📝 Active |
| Scribe | Session Logger | .squad/agents/scribe/charter.md | 📋 Built-in |
| Ralph | Work Monitor | .squad/agents/ralph/charter.md | 🔄 Built-in |
| Rai | RAI Reviewer | .squad/agents/Rai/charter.md | 🛡️ Built-in |
| Fact Checker | Verification & Devil's Advocate | .squad/agents/fact-checker/charter.md | 🔍 Built-in |


## Coding Agent

<!-- copilot-auto-assign: false -->

| Name | Role | Charter | Status |
|------|------|---------|--------|
| @copilot | Coding Agent | — | 🤖 Coding Agent |

### Capabilities

**🟢 Good fit — auto-route when enabled:**
- Bug fixes with clear reproduction steps
- Test coverage (adding missing tests, fixing flaky tests)
- Lint/format fixes and code style cleanup
- Dependency updates and version bumps
- Small isolated features with clear specs
- Boilerplate/scaffolding generation
- Documentation fixes and README updates

**🟡 Needs review — route to @copilot but flag for squad member PR review:**
- Medium features with clear specs and acceptance criteria
- Refactoring with existing test coverage
- API endpoint additions following established patterns
- Migration scripts with well-defined schemas

**🔴 Not suitable — route to squad member instead:**
- Architecture decisions and system design
- Multi-system integration requiring coordination
- Ambiguous requirements needing clarification
- Security-critical changes (auth, encryption, access control)
- Performance-critical paths requiring benchmarking
- Changes requiring cross-team discussion

## Project Context

- **Project:** layered-platform-alm — Layered Platform ALM (LP-ALM) methodology reference & template
- **Domain:** Layered Power Platform / Dataverse solutions for enterprise & government (GCC High / FedRAMP / DoD)
- **Cast universe:** The Matrix
- **Requested by:** Devon Aleshire
- **Coordinator alias:** Neo
- **Public site:** https://devonaleshiremsft.github.io/layered-platform-alm/
- **Created:** 2026-07-27
