function Add-ConfigurationVariable {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding()]
    param (
        [PSCustomObject]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        $InputObject,

        [String]
        [Parameter(Position = 0, Mandatory = $true)]
        $Name,

        [String]
        [Parameter(Position = 1, Mandatory = $true)]
        $Value,

        [String]
        [Parameter(Mandatory = $true)]
        $Scope,

        [String]
        [Parameter(Mandatory = $true)]
        $ScopeName
    )

    begin {

    }

    process {
        $_
    }

    end {
        New-ConfigurationVariable `
            -Name $Name `
            -Value $Value `
            -Scope $Scope `
            -ScopeName $ScopeName
    }
}
