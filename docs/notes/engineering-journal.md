# Engineering Journal

## Remediation approach locked

Forge's remediation approach was locked: fix the three findings Hunt left open
(F-01 Kerberoastable Domain Admin service account, F-02 LLMNR/NBT-NS enabled,
F-03 weak passwords), remediate in place rather than delete, and validate every
fix by re-running the Hunt attack that exploited it. Both decisions and their
reasoning are recorded in the engineering decisions.

## F-02 closed, after an mDNS detour

LLMNR was disabled through a domain-linked GPO (the first real Group Policy in
the portfolio, which Atlas deliberately deferred), and NBT-NS through a startup
script setting NetbiosOptions on every interface. The registry on WS01
confirmed both were off.

The first re-attack was the useful part. Responder still captured a hash, but
the poisoned answers had switched from LLMNR and NBT-NS to mDNS. Modern Windows
answers a third name-resolution protocol, Multicast DNS, that the classic
"disable LLMNR and NBT-NS" advice leaves open, and Responder poisons it too.
Extending the startup script to also disable mDNS (EnableMDNS = 0) and
re-running finally produced the intended result: no poisoned answers of any
kind and no capture. This was a good reminder that validation by re-attack
catches gaps a settings review would miss, which is exactly why the project
tests every fix instead of trusting it.

## F-01 closed, with a grace-window lesson

svc-appsvc was removed from Domain Admins, reset to a long random password, and
restricted to AES encryption. The group-membership and encryption changes
verified cleanly on the DC.

The password change produced a confusing moment: the old password still
authenticated over SMB right after the reset. PasswordLastSet proved the reset
had applied, and the cause turned out to be the NTLM old-password grace window,
which keeps accepting the previous password over NTLM for about an hour after a
change. Kerberos does not honour that grace, so the Kerberoast re-attack showed
the true state at once: svc-appsvc no longer a Domain Admin, and the service
ticket returned as AES256 rather than the RC4 that made Kerberoasting cheap in
Hunt. Worth remembering that a reset credential can look alive over NTLM for an
hour.

## F-03 closed

The Default Domain Policy was raised to a 15-character minimum with lockout, and
a fine-grained policy gave service accounts a stricter 25-character floor,
confirmed resolving onto svc-appsvc. The cleanest proof came for free: the
domain now refuses to even set Password1, the exact weak password cracked in
Hunt, returning a complexity exception. The weak-credential path is closed at
the policy level, not just on one account.

## Portfolio complete

With all three findings remediated and each proven by re-attack, Forge v1.0 is
done, and with it the whole WolfSec Labs arc: Atlas built the enterprise,
Sentinel watched it, Hunt attacked it, and Forge hardened what Hunt found and
proved the fixes hold.
