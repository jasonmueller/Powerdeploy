function GetSettingsFromUri {
    param (
        [Parameter(Mandatory = $true)]
        $uri,
        [Parameter(Mandatory = $true)]
        $environmentName,
        [string]$computer,
        [string]$role
    )

    function main {
        Write-Verbose "Attempting to load settings from requested URI ($uri)..."
        $parsedUri = New-Object System.Uri $uri

        if ($parsedUri.Scheme -ne 'file') {
            throw 'Only filesystem based settings are currently supported.'
        }

        # Delegate to the file system settings provider.
        $fn = & { .$PSScriptRoot\Includes\GetSettingsFromUri-FileSystemSingleSettingsPson.ps1; Get-Command GetSettingsFromUri | Select -Expand ScriptBlock }

        &$fn $uri $environmentName $computer $role
    }

    main
}