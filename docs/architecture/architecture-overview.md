# Architecture Overview

**Project:** Forge

**Portfolio:** WolfSec Labs

**Status:** Draft

## Overview

Forge is the fourth project in the WolfSec Labs portfolio. It doesn't build
infrastructure, add monitoring, or attack anything. It hardens the environment
against the specific weaknesses Hunt demonstrated, and validates each fix by
re-running the attack that exploited it.

## What already exists

Forge changes the same environment the rest of the portfolio built and used:

- **DC01** – Domain controller, `apexdynamics.internal`, where most hardening
  is applied (GPO, AD account changes, password policy)
- **WS01** – Domain-joined client, where GPO-based fixes land and are verified
- **APP01** – Ubuntu server, not a target of this hardening pass
- **KALI01** – Attack platform, used again here to re-run the Hunt attacks and
  prove the fixes hold
- **MON01** – Wazuh, still watching, so the hardening work is itself visible

## Scope

Forge addresses the three findings left open by Hunt:

| Finding | Weakness | Fix |
|---|---|---|
| F-01 | `svc-appsvc`: Kerberoastable and a Domain Admin | Remove from Domain Admins, strong managed credential, enforce AES |
| F-02 | LLMNR/NBT-NS enabled by default | Disable both by Group Policy |
| F-03 | Weak, crackable passwords | Strengthen domain policy, reset weak credentials, add a fine-grained policy for service accounts |

F-04 (a Kerberoasting detection gap) was already closed during Hunt with a
custom Wazuh rule, so it is not repeated here.

## Approach

Two principles shape the work, both carried from the earlier projects.

First, remediate in place rather than delete. `svc-appsvc` was planted for
Hunt, so deleting it would technically close F-01, but that demonstrates
nothing and doesn't resemble real remediation, where a service account almost
always has an application depending on it. Forge hardens the account the way a
real environment would have to.

Second, prove every fix by re-attack. A control that isn't tested is an
assumption. After each fix, the exact Hunt attack step that exploited the
weakness is re-run, and the result is recorded. The hardening is only
considered done when the attack that used to work no longer does.

## Relationship to other projects

- **Atlas** built the environment and deferred Group Policy until there was a
  reason to apply it. Forge is that reason.
- **Sentinel** monitors the environment, including the hardening changes
  themselves.
- **Hunt** produced the findings Forge consumes, and its attack chain is the
  validation harness Forge tests against.

## Current Status

Remediation scope locked. Hardening execution starts next, finding by finding,
each followed by its re-attack proof.
