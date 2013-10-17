function GetSettingsFromUri {
    param (
        [Parameter(Mandatory = $true)]
        $settingsRootFolder,
        [Parameter(Mandatory = $true)]
        $environmentName,
        [Parameter(Mandatory = $true)]
        $packageName,
        [string]$computer,
        [string]$role
    )

    function main {
        Write-Verbose "Locating application settings file for package '$packageName' in '$settingsRootFolder'..."

        $packagesPath = Join-Path $settingsRootFolder packages
        $packageSettingsPath = Join-Path $packagesPath $packageName
        $packageSettingsFilePath = Join-Path $packageSettingsPath settings.pson

        $environmentsPath = Join-Path $settingsRootFolder env
        $thisEnvironmentSettingsPath = Join-Path $environmentsPath $environmentName
        $thisEnvironmentSettingsFilePath = Join-Path $thisEnvironmentSettingsPath settings.pson
        $allEnvironmentsSettingsFilePath = Join-Path $environmentsPath settings.pson
        $thisEnvironmentSettings = @{}

        $settingsPath = $allEnvironmentsSettingsFilePath

        if (!(Test-Path $settingsPath)) {
            $settingsPath = $thisEnvironmentSettingsFilePath

            if (Test-Path $thisEnvironmentSettingsFilePath) {
                $thisEnvironmentSettings = Invoke-Expression (getReplacedContent $thisEnvironmentSettingsFilePath @{})
            }

            if (!(Test-Path $settingsPath)) {
                $settingsPath = $packageSettingsFilePath
            }
        }

        Write-Verbose "Settings were found at $settingsPath.  Settings will be parsed."

        $settings = Invoke-Expression (getReplacedContent $settingsPath $thisEnvironmentSettings)

        $settings
    }

    function getReplacedContent($path, $variables) {
        $content = Get-Content $path | Out-String

        foreach ($var in $variables.Keys){
            Write-Host $var
            Write-Host $content
            $content = $content -replace "`${env:$($var)}",$variables[$var] 
        }

        $content
    }

    main
}