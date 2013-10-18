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

        getSettingsFromEnvironmentOrGlobal $parsedUri.LocalPath $environmentName $computerName
    }

    function getSettingsFromEnvironmentOrGlobal(
        $settingsFolderPath,
        $environmentName,
        $computerName) { 
        
        $globalSettingsFilePath = Join-Path $parsedUri.LocalPath Settings.pson
        $settings = getSettingsFromEnvironments $parsedUri.LocalPath $environmentName
        if ($settings -eq $null) {
           $settings = getSettingsFromGlobal $globalSettingsFilePath $environmentName $computer    
        }
        else {
            if (Test-Path $globalSettingsFilePath) {
                Write-Warning ('Settings files were found for the environment and a global (old-style) '`
                    + 'file was found.  The environment-specific settings file will be used.')
            }
        }

        $settings
    }

    function getSettingsFromGlobal(
        $settingsFilePath,
        $environmentName,
        $computerName) {

        $fn = & { .$PSScriptRoot\Includes\GetSettingsFromUri-FileSystemSingleSettingsPson.ps1; Get-Command GetSettingsFromUri | Select -Expand ScriptBlock }

        &$fn $uri $environmentName $computer $role
    }

    function getSettingsFromEnvironments(
        $settingsFolderPath,
        $environmentName) {

        & {
            . $PSScriptRoot\Includes\GetSettingsForEnvironment-FileSystemHierarchy.ps1
            GetSettingsForEnvironment -SettingsFolderPath $settingsFolderPath -EnvironmentName $environmentName
        }
    }

    main
}