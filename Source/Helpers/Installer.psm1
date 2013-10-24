$helpersPath = (Split-Path -parent $MyInvocation.MyCommand.Definition);

# Grab functions from files.
Resolve-Path $helpersPath\functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

Export-ModuleMember -Function `
    Get-DeploymentEnvironmentName `
    Get-DeploymentFolder


