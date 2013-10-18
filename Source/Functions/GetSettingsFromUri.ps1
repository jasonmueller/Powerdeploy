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

        $effectiveSettings = getSettingsFromEnvironmentOrGlobal $parsedUri.LocalPath $environmentName $computerName

        if (!([String]::IsNullOrWhiteSpace($computer))) {
            mergeOverrides $effectiveSettings 'Computers' $computer
        }

        if (!([String]::IsNullOrWhiteSpace($role))) {
            mergeOverrides $effectiveSettings 'Roles' $role
        }

        $effectiveSettings.Remove('Overrides')
        $effectiveSettings
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

    function mergeOverrides($settings, $keyName, $keyValue) {
        Write-Verbose "Looking for $keyName overrides for $keyValue..."

        $overrides = $effectiveSettings.Overrides
        if ($overrides -ne $null -and $overrides[$keyName] -ne $null) {
            $innerSettings = $overrides[$keyName][$keyValue]

            if ($innerSettings -ne $null) {
                Write-Verbose "Overrides were found for $keyValue."
                mergeSettings $effectiveSettings $innerSettings
            }
            else {
                Write-Warning "$keyValue was specified for $keyName override but no such settings exist.  If you expected overrides for this, ensure the overrides exist in deployment settings."
            }        
        } 
        else {
            Write-Warning "There are no overrides for the specified environment.  $keyValue overrides for $keyName will be skipped."
        }
    }

    function mergeSettings($target, $source) {
        foreach ($pair in $source.GetEnumerator()) {
            if ($target[$pair.Key] -ne $null) {
                $target[$pair.Key] = $pair.Value
               Write-Verbose "Merging setting for $($pair.Key)."
            }
        }
    }

    main
}