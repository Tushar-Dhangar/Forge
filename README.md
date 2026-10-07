# Forge

**WolfSec Labs** — building, breaking and defending enterprise systems.

Forge is the fourth and final repository in the WolfSec Labs portfolio. It
closes the loop: it hardens the exact weaknesses Hunt proved exploitable, and
then re-runs Hunt's attack chain to show each fix actually holds. Nothing here
is a hypothetical control. Every change traces back to a specific finding, and
every fix is validated by re-attack rather than assumed.

## What Forge fixes

The input to Forge is the Hunt findings report. Three findings were left open
at the end of that engagement (the fourth, a detection gap, was already closed
during Hunt itself):

- **F-01** — a Kerberoastable service account (`svc-appsvc`) that was also a
  member of Domain Admins
- **F-02** — LLMNR/NBT-NS broadcast name resolution enabled by default, the
  initial-access vector
- **F-03** — weak, wordlist-crackable account passwords

## How it works

Each finding is hardened, then the corresponding step of the Hunt attack chain
is re-run to confirm it no longer works:

- LLMNR/NBT-NS disabled by Group Policy, then Responder is re-run and captures
  nothing.
- `svc-appsvc` stripped of Domain Admins, given a strong managed credential,
  and forced to AES, then Kerberoasting is re-run and leads nowhere.
- Password policy strengthened and weak credentials reset, then offline
  cracking of any remaining captured material fails.

This is the first repository in the portfolio to implement Group Policy, since
Atlas deliberately deferred it until there was a concrete reason to apply it.
Forge is that reason.

## Relationship to the rest of the portfolio

Forge changes the live environment Atlas built, Sentinel watches and Hunt
attacked. It doesn't rebuild anything. What's documented here is only the
hardening: what was changed, why, and the before/after evidence from re-running
the attacks.

## Repository layout

- `docs/architecture/` — remediation scope and approach
- `docs/engineering-decisions/` — the reasoning behind the hardening choices
- `docs/setup/` — the hardening guide: each fix and its re-attack proof
- `docs/notes/` — engineering journal
- `assets/diagrams/` — before/after diagrams
- `assets/screenshots/` — evidence captures
- `scripts/` — supporting automation

## Roadmap

- Remediation scope and approach — complete
- F-02 fix: disable LLMNR/NBT-NS by GPO — planned
- F-01 fix: remediate the service account (least privilege, AES) — planned
- F-03 fix: password policy and fine-grained policy — planned
- Re-attack validation — planned
- Forge v1.0 — planned

## WolfSec Labs portfolio

Atlas → Sentinel → Hunt → **Forge**

Atlas built the enterprise. Sentinel watches it. Hunt attacked it. Forge
hardens what Hunt found and proves the fixes hold, completing the build,
monitor, attack, defend lifecycle the portfolio set out to tell.
