<#
    Disable-LegacyNameResolution.ps1
    Disables the legacy broadcast/multicast name-resolution protocols that
    Responder abuses to capture credentials: NBT-NS and mDNS.

    Deployed as a computer Startup script via the "Disable LLMNR and NBT-NS"
    GPO. LLMNR is disabled separately by that GPO's "Turn off multicast name
    resolution" administrative template. NBT-NS and mDNS have no native
    Group Policy templates, so they are set here via the standard registry
    method:

      NBT-NS : NetbiosOptions = 2 on every interface
      mDNS   : EnableMDNS = 0 under the Dnscache service

    Together with the LLMNR GPO setting, this removes every client-side
    name-resolution fallback Responder can poison. Disabling only LLMNR and
    NBT-NS is insufficient on Windows 10/11, which still answers mDNS.
#>

# NBT-NS: disable on all network adapters
$interfaces = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces'
foreach ($interface in $interfaces) {
    Set-ItemProperty -Path $interface.PSPath -Name NetbiosOptions -Value 2
}

# mDNS: disable
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name EnableMDNS -Value 0 -Type DWord
