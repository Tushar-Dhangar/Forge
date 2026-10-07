# ADR-001: Remediation Approach

**Status:** Accepted

## Background

Hunt left three findings open: a Kerberoastable Domain Admin service account
(F-01), default-enabled LLMNR/NBT-NS (F-02), and weak passwords (F-03). Forge
needs to fix all three, but there's more than one way to close each, and the
choices shape both the work and what the project demonstrates.

## Decision

Each finding is remediated with the control a real environment would use, and
`svc-appsvc` specifically is hardened in place rather than deleted.

- **F-02 (LLMNR/NBT-NS):** disabled through Group Policy, applied at the domain
  level so every current and future Windows host inherits it.
- **F-01 (`svc-appsvc`):** removed from Domain Admins, given a long random
  password, and configured for AES encryption only. The account stays, hardened.
- **F-03 (passwords):** the Default Domain Policy is strengthened to require
  length over complexity, the deliberately weak credentials are reset, and a
  fine-grained password policy is added targeting service accounts with
  stricter rules than ordinary users.

## Why this decision?

The alternative for F-01 was simply deleting `svc-appsvc`. It was planted for
Hunt and no real service uses it, so deletion would close the finding. It was
rejected because it demonstrates nothing and doesn't match reality. In a real
environment a service account exists because an application authenticates with
it, and you can't delete it without breaking that application. The actual skill
being tested is remediating an over-privileged account while keeping it
functional: strip the excess privilege, replace the weak static password with a
managed one, and remove the weak RC4 encryption that made Kerberoasting cheap.
Hardening the account in place is the realistic exercise; deleting it is
avoiding it.

For the service account's credential, a Group Managed Service Account (gMSA) is
the production-grade answer, since it removes human-set passwords entirely and
rotates automatically. It's documented here as the recommendation. In the lab,
where no computer actually consumes `svc-appsvc`, a full gMSA adds KDS root key
propagation and host-authorization steps for no real payoff, so the lab
implements the next best thing: a long random password plus AES enforcement.
The Kerberoasting defence, a strong password the offline crack can't recover
and AES instead of RC4, is demonstrated either way.

Applying F-02 by Group Policy rather than host by host matters for the same
reason static addressing mattered in Atlas: it's how the control actually
scales. A per-host registry edit fixes one machine; a domain GPO fixes the
estate and every machine added to it later. This is also the portfolio's first
real use of Group Policy, which Atlas deliberately deferred until a concrete
need existed, and hardening is that need.

The fine-grained password policy for F-03 reflects that service accounts and
human users have different risk profiles. A service account password is set
once and rarely typed, so it can and should be far longer than what's
reasonable to ask a person to use. A domain-wide policy sets the floor for
everyone; a fine-grained policy raises it specifically for the accounts that
Kerberoasting targets.

## Trade-offs

Remediating in place is more work than deleting, and the gMSA recommendation
is documented rather than fully implemented in the lab. Both are deliberate:
the goal is to demonstrate the real remediation technique and reasoning, not to
chase a perfect-score configuration on an account nothing actually uses.

## Outcome

Each fix is applied as described and then validated by re-attack, recorded in
[ADR-002](002-validation-by-reattack.md) and the
[hardening guide](../setup/hardening-guide.md).
