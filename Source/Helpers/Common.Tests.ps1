
# Include all of the files that will be included when the Installer module is loaded
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Resolve-Path $here\Functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }
