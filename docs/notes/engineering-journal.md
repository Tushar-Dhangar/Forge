# Engineering Journal

Forge's remediation approach is locked: fix the three findings Hunt left open
(F-01 Kerberoastable Domain Admin service account, F-02 LLMNR/NBT-NS enabled,
F-03 weak passwords), remediate in place rather than delete, and validate every
fix by re-running the Hunt attack that exploited it. Both decisions and their
reasoning are recorded in the engineering decisions. Hardening entries start
once the work is applied.
