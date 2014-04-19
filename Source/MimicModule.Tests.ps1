$mimichere = (Split-Path -parent $MyInvocation.MyCommand.Definition)

# Grab functions from files.
Resolve-Path $mimichere\Functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { Write-Verbose "sourcing>>> $($_.ProviderPath)"; . $_.ProviderPath }
