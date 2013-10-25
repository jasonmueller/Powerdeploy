$here = (Split-Path -parent $MyInvocation.MyCommand.Definition)

# Grab functions from files.
Resolve-Path $here\Functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

Export-ModuleMember `
    Get-DeploymentEnvironmentName, `
    Get-DeploymentFolder,
    Set-DeploymentContext


