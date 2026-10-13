# Forge Hardening Guide

## Purpose

This records each hardening change applied to the environment and the
re-attack result that proves it worked. It is written from the completed work
so the hardening can be reviewed or reproduced without relying on chat history.

Every fix below is paired with the Hunt attack step it addresses, following
the validation-by-re-attack approach from
[ADR-002](../engineering-decisions/002-validation-by-reattack.md). A change is
only treated as done when the attack that used to work no longer does.

## F-02: disable LLMNR, NBT-NS and mDNS

### The fix

LLMNR was disabled through a Group Policy Object, "Disable LLMNR and NBT-NS",
linked at the domain root so every Windows host inherits it. The setting is
Computer Configuration, Policies, Administrative Templates, Network, DNS
Client, "Turn off multicast name resolution", Enabled.

NBT-NS has no native Group Policy template, so it was disabled with a computer
Startup script deployed through the same GPO, setting NetbiosOptions = 2 on
every interface. The script is in scripts/Disable-LegacyNameResolution.ps1.

### The mDNS discovery

The first re-attack showed why validation matters. After disabling LLMNR and
NBT-NS and confirming both in the registry on WS01 (EnableMulticast = 0,
NetbiosOptions = 2), Responder was re-run. It still captured a hash, but the
poisoned-answer lines had changed: no more LLMNR or NBT-NS entries, only MDNS.
The lookup had fallen through to mDNS, a third name-resolution protocol enabled
by default on Windows 10 and 11, which Responder also poisons.

Disabling LLMNR and NBT-NS is the classic advice, but on modern Windows it
leaves mDNS open. The startup script was extended to also set EnableMDNS = 0
under the Dnscache service. After a reboot and re-run, Responder captured
nothing: no LLMNR, NBT-NS or MDNS poisoned answers, and no hash. The failed
UNC lookup on WS01 simply went nowhere, which is the point: with every
broadcast fallback disabled, the name cannot be hijacked.

### Re-attack result

Running the exact Hunt initial-access attack (Responder on KALI01, a failed
UNC lookup on WS01 as james.whitmore) now captures no credential at all. The
initial-access vector is closed.

## F-01: remediate the svc-appsvc service account

### The fix

Three changes on DC01, addressing both halves of the finding (excessive
privilege and a cheaply-crackable Kerberos ticket): remove the account from
Domain Admins, reset it to a long random password that is not recorded
anywhere, and set msDS-SupportedEncryptionTypes to 24 so it supports AES only
and no longer offers the RC4 that makes Kerberoasting cheap.

The account was hardened in place rather than deleted, for the reasons in
[ADR-001](../engineering-decisions/001-remediation-approach.md). A Group
Managed Service Account is the production-grade answer and is documented there
as the recommendation; in the lab, where nothing consumes the account, a long
random password plus AES enforcement demonstrates the same Kerberoasting
defence without the KDS key setup a gMSA needs.

### The NTLM old-password gotcha

Immediately after the reset, a check with the old password still succeeded over
SMB, which looked like the reset had failed. It had not: PasswordLastSet
confirmed the change had applied. The cause is the NTLM old-password grace
window (OldPasswordAllowedPeriod), which by default keeps accepting the previous
password over NTLM for about 60 minutes after a change, to tolerate cached
credentials on devices. Kerberos does not honour this grace, so the Kerberoast
re-attack, which uses Kerberos, reflected the true state immediately. This is a
genuine gotcha worth knowing: a freshly-reset account can still authenticate
with its old password over NTLM for an hour, which can mislead both an attacker
and a defender checking their own work.

### Re-attack result

Re-running the Kerberoast (GetUserSPNs -request) shows the change clearly.
Before, in Hunt, svc-appsvc showed MemberOf of Domain Admins and returned an
RC4 ticket (krb5tgs type 23). After Forge, MemberOf is empty (an ordinary
Domain User) and the ticket comes back AES256 (krb5tgs type 18).

The ticket is still issued, since any domain user can request a service ticket
for an account with an SPN, but it is now AES-encrypted and protected by a
30-character random password, so offline cracking is infeasible. And because
the account is no longer a Domain Admin, cracking it would yield nothing but an
ordinary user. Both halves of the finding are closed.

## F-03: password policy

### The fix

Three parts. First, the Default Domain Policy was strengthened to a 15-character
minimum with complexity, a 24-password history, a 90-day maximum age, and
account lockout after 5 attempts. Length is the primary defence here, since it
resists offline cracking far better than complexity rules alone.

Second, a fine-grained password policy (PSO-ServiceAccounts, precedence 10,
25-character minimum) was created and applied to a new GG-ServiceAccounts
group, with svc-appsvc as a member. Service accounts can tolerate much longer
passwords than humans because the password is set once and never typed.
Get-ADUserResultantPasswordPolicy on svc-appsvc confirms the PSO resolves onto
it, while ordinary users remain on the 15-character domain default.

Third, the deliberately weak credentials from the Hunt setup were reset.
svc-appsvc already received a strong random password during F-01, and
james.whitmore was reset to a compliant passphrase.

### Re-attack result

The clearest proof is that the policy now actively rejects the weak password
that was cracked in Hunt. Attempting to set Password1 fails with an
ADPasswordComplexityException ("The password does not meet the length,
complexity, or history requirement of the domain"), while a compliant
19-character passphrase sets successfully. The weak-credential path that made
the Hunt hash crack instantly is closed at the policy level, not just for one
account.

## Outcome

All three findings Hunt left open are remediated and validated by re-attack.
The one finding Hunt closed during its own engagement (F-04, the Kerberoasting
detection rule) remains in place in Sentinel. The environment now resists the
full Hunt attack chain: initial access captures nothing, the service account
offers no escalation path, and weak passwords are rejected outright.

## Remediation scripts

The exact commands used for each fix are captured as runnable scripts in
`scripts/`, so the remediation can be reviewed or reapplied without
reconstructing it from this guide:

- `Disable-LegacyNameResolution.ps1` (F-02): disables NBT-NS and mDNS per host
  (LLMNR is handled by the GPO administrative template)
- `Remediate-ServiceAccount.ps1` (F-01): least privilege, strong password and
  AES enforcement for the service account
- `Set-PasswordPolicy.ps1` (F-03): the Default Domain Policy and the
  fine-grained service-account policy
