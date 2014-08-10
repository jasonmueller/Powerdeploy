param (
    [String]
    [Parameter(Position = 0, Mandatory = $true)]
    $PackageArchive,

    [String]
    [Parameter(Position = 1, Mandatory = $true)]
    $EnvironmentName,

    [String]
    [Parameter(Position = 2, Mandatory = $true)]
    $ComputerName,

    [System.Uri]
    [Parameter(Position = 3, Mandatory = $true)]
    $SettingsPath
)

if (-not (Get-Module Powerdeploy)) {
    $shouldUnload = $true

    Import-Module "$PSScriptRoot\..\Powerdeploy"
}

$configurationVariables = Get-ConfigurationVariable -SettingsPath $SettingsPath
$applicableVariables = $configurationVariables | `
    Resolve-ConfigurationVariable `
        -EnvironmentName $EnvironmentName `
        -ComputerName $ComputerName `
        -AsHashTable

Invoke-Powerdeploy `
    -PackageArchive $PackageArchive `
    -Environment $EnvironmentName `
    -ComputerName $ComputerName `
    -Variable $applicableVariables `
    -Verbose

if ($shouldUnload) {
    Remove-Module Powerdeploy
}