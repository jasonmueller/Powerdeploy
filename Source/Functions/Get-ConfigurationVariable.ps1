function Get-ConfigurationVariable {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
    param (
        [System.Uri]
        [Parameter(Mandatory = $true)]
        $SettingsPath,

        [string]
        [Parameter(ParameterSetName = "Review", Mandatory = $false)]
        $EnvironmentName,

        [string]
        [Parameter(ParameterSetName = "Review", Mandatory = $false)]
        $Name
    )

    function New-DeploymentVariable($scope, $scopeName, $dictionary) {
        $dictionary.GetEnumerator() | % { 
            $settingName = $_.Name
            $settingValue = $_.Value

            if ($settingName -eq 'Overrides') {
                $settingValue.Computers.GetEnumerator() | % {
                    New-DeploymentVariable @('Environment', 'Computer') @($environmentName, ($_.Name)) $_.Value
                }
            }
            else {
                New-Object PSObject -Property @{
                    Type = 'NameValue'
                    Name = $settingName
                    Value = $settingValue
                    Scope = $scope
                    ScopeName = $scopeName
                }
            }
        }
    }

    function processPsonSettings($path) {
        $settings = Invoke-Expression (Get-Content $path | out-string)

        $settings.environments.GetEnumerator() | % { 
            $environmentName = $_.Name
            $members = $_.Value

            New-DeploymentVariable @('Environment') @($environmentName) $members
        }
    }

    Write-Verbose "Attempting to load settings from requested URI ($SettingsPath)..."
    $parsedUri = New-Object System.Uri $SettingsPath

    if ($parsedUri.Scheme -ne 'file') {
        throw 'Only filesystem based settings are currently supported.'
    }

    $psonPath = Join-Path $SettingsPath.LocalPath Settings.pson

    if (!(Test-Path $psonPath)) {
            throw 'No settings file was found in the specified path.'
        }

    $results = processPsonSettings($psonPath)

    if (-not [String]::IsNullOrEmpty($EnvironmentName)) {
        $results = $results | Where-Object { $_.Scope -contains 'Environment' -and $_.ScopeName[0] -eq $EnvironmentName }
    }

    $results
}
