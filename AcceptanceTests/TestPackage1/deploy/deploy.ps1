Write-Host "Variable Debug:"
Get-DeploymentVariable
Get-DeploymentVariable -Name UserDb

$folder = Get-DeploymentFolder

"deploy script executed" >> $folder\install.log

#$global:pddeploymentcontext.settings.getenumerator() | select key,value |  Write-Host 