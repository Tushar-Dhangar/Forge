<#
    Remediate-ServiceAccount.ps1
    Hardens the svc-appsvc service account (Hunt finding F-01):
      - removes it from Domain Admins (least privilege)
      - resets it to a long random password (not recorded anywhere)
      - enforces AES-only Kerberos encryption, removing RC4

    Addresses both halves of the finding: excessive privilege, and a
    cheaply-crackable RC4 Kerberos service ticket. A Group Managed Service
    Account (gMSA) is the production-grade credential option; this uses a long
    random password where no host actually consumes the account.
#>

param(
    [string]$Identity = 'svc-appsvc'
)

Import-Module ActiveDirectory

# Least privilege: remove from Domain Admins
Remove-ADGroupMember -Identity 'Domain Admins' -Members $Identity -Confirm:$false

# Strong, unrecorded password
Add-Type -AssemblyName System.Web
$pw = [System.Web.Security.Membership]::GeneratePassword(30, 6)
Set-ADAccountPassword -Identity $Identity -Reset -NewPassword (ConvertTo-SecureString $pw -AsPlainText -Force)
Remove-Variable pw

# Enforce AES only (24 = AES128 + AES256), removing RC4
Set-ADUser -Identity $Identity -Replace @{'msDS-SupportedEncryptionTypes' = 24}
