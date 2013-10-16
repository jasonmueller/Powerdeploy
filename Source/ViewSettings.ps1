param (
    $SettingsUri,
    $Environment,
    $Computer,
    $Role
)

$scriptPath = (Split-Path $MyInvocation.MyCommand.Path -Parent)
. (Resolve-Path $scriptPath\Functions\GetSettingsFromUri.ps1)


('='*40)
"Displaying settings for"
"    Environment: $Environment"
"    Computer: $Computer"
"    Role: $Role"

GetSettingsFromUri $settingsUri $Environment $Computer $Role
