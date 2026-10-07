# ADR-002: Validation by Re-attack

**Status:** Accepted

## Background

Forge applies three fixes. The question is how to know they worked. A hardening
change can look correct in a settings dialog and still fail to stop the attack
it was meant to stop, through a missed scope, an unapplied policy, or a
misunderstanding of what the control actually does.

## Decision

Every fix is validated by re-running the exact Hunt attack step that exploited
the weakness, and confirming it now fails. A fix is not considered done because
the setting was changed; it's done when the attack that used to work no longer
does.

- After disabling LLMNR/NBT-NS, Responder is re-run on KALI01 and must capture
  nothing from WS01.
- After remediating `svc-appsvc`, the Kerberoasting attack is re-run and must
  either return no useful ticket or a credential that can't be cracked, and in
  no case lead to Domain Admin.
- After the password changes, any captured hash must resist offline cracking.

## Why this decision?

This is the whole reason the portfolio built Hunt before Forge. The attack
chain already exists, it's documented step by step, and it's known to work
against the unhardened environment. That makes it a ready-made test harness:
the same commands that proved the weakness can prove the fix, with the result
simply inverted from success to failure.

Validating by re-attack also catches the specific failure mode that makes
hardening deceptive: a control applied but not effective. Disabling LLMNR in a
GPO that never reaches WS01, or setting a strong password on an account that
still has an RC4 service ticket available, would both pass a settings review
and fail a real test. Re-running the attack is the only check that actually
exercises the control.

There's a reporting benefit too. "LLMNR disabled" is a claim; "Responder
re-run, zero hashes captured, screenshot attached" is evidence. The before and
after from the same tool, against the same target, is exactly what a remediation
report should contain, and it's far more convincing than a list of changed
settings.

## Trade-offs

Re-attacking takes longer than just applying the fixes and moving on, and it
means keeping KALI01 and the attack tooling in play through the hardening phase
rather than standing down after Hunt. That's an acceptable cost for being able
to prove, rather than assert, that the environment is actually more secure.

## Outcome

Each fix in the [hardening guide](../setup/hardening-guide.md) is paired with
its re-attack result, forming a before-and-after record for the whole
remediation.
