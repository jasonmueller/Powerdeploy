function New-ConfigurationVariable {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding()]
    param (
        [String]
        [Parameter(Mandatory = $true)]
        $Name,

        [String]
        [Parameter(Mandatory = $true)]
        $Value,

        [String[]]
        [Parameter(Mandatory = $true)]
        $Scope,

        [String[]]
        [Parameter(Mandatory = $true)]
        $ScopeName
    )

    New-Object PSObject -Property @{
        Type = 'NameValue'
        Name = $Name
        Value = $Value
        Scope = $Scope
        ScopeName = $ScopeName
    }
}
