function Using-Module {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ScriptBlock]
        $Script = { }
    )

    $here = $PSScriptRoot
    $modulePath = Resolve-Path $here\..\_build\Powerdeploy.psd1

    Import-Module $modulePath

    & $Script

    Remove-Module Powerdeploy

}

