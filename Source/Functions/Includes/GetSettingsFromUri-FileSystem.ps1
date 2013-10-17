function GetSettingsFromUri {
    param (
        [Parameter(Mandatory = $true)]
        $uri,
        [Parameter(Mandatory = $true)]
        $environmentName,
        [string]$computer,
        [string]$role
    )

    Write-Host $uri
}