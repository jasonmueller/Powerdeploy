function Unload-WebAdministration {
    $iisVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp";
    if ($iisVersion.MajorVersion -eq 7)
    {
        if ($iisVersion.MinorVersion -ge 5)
        {
            Remove-Module WebAdministration;
        }           
        else
        {
            if (-not (Get-PSSnapIn | Where {$_.Name -eq "WebAdministration";})) {
                Remove-PSSnapIn WebAdministration;
            }
        }
    }
}