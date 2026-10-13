<#
    Set-PasswordPolicy.ps1
    Strengthens password policy (Hunt finding F-03):
      - raises the Default Domain Policy to a 15-character minimum
      - adds a fine-grained policy (PSO) for service accounts at 25 characters

    Length is the primary defence, since it resists offline cracking far better
    than complexity rules alone. Service accounts get a stricter PSO because
    their passwords are set once and never typed by a human.
#>

Import-Module ActiveDirectory

$domain = 'apexdynamics.internal'

# Default Domain Policy
Set-ADDefaultDomainPasswordPolicy -Identity $domain `
    -MinPasswordLength 15 -ComplexityEnabled $true -PasswordHistoryCount 24 `
    -MaxPasswordAge '90.00:00:00' -LockoutThreshold 5 `
    -LockoutDuration '00:15:00' -LockoutObservationWindow '00:15:00'

# Fine-grained password policy for service accounts
New-ADGroup -Name 'GG-ServiceAccounts' -GroupScope Global -GroupCategory Security `
    -Path 'OU=Groups,OU=Apex,DC=apexdynamics,DC=internal'
Add-ADGroupMember -Identity 'GG-ServiceAccounts' -Members 'svc-appsvc'

New-ADFineGrainedPasswordPolicy -Name 'PSO-ServiceAccounts' -Precedence 10 `
    -MinPasswordLength 25 -ComplexityEnabled $true -PasswordHistoryCount 24 `
    -MaxPasswordAge '365.00:00:00' -LockoutThreshold 5 `
    -LockoutDuration '00:30:00' -LockoutObservationWindow '00:30:00'

Add-ADFineGrainedPasswordPolicySubject -Identity 'PSO-ServiceAccounts' -Subjects 'GG-ServiceAccounts'
