function Load-WebAdministration {
    $iisVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp";
    if ($iisVersion.MajorVersion -eq 7)
    {
        if ($iisVersion.MinorVersion -ge 5)
        {
            Import-Module WebAdministration -Verbose:$false
        }           
        else
        {
            if (-not (Get-PSSnapIn | Where {$_.Name -eq "WebAdministration";})) {
                Add-PSSnapIn WebAdministration;
            }
        }
    }
}