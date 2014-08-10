function Resolve-ConfigurationVariable {
    # .ExternalHelp ..\powerdeploy.psm1-help.xml
    [CmdletBinding(DefaultParameterSetName="__AllParameterSets")]
    param (
        [PSCustomObject[]]
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        $InputObject,

        [String]
        [Parameter(Mandatory = $true)]
        $EnvironmentName,

        [String]
        [Parameter(Mandatory = $true)]
        $ComputerName,

        [Switch]
        [Parameter(Mandatory = $false)]
        $AsHashTable = $false
    )

    begin {
        $buffer = @()
        $useHashTable = ($AsHashTable)
    }

    process {
        # We can't just stream the results back out because we might
        # see an environment-scoped variable prior to seeing a computer-scoped
        # one and we don't want to output both.
        $buffer += $_
    }

    end {

        # We need to sort the variables so we can output the computer-scoped ones
        # first and ignore any matching environment-scoped ones.  Variables with
        # no computer-scoped will get the environment-scoped.
        $buffer = $buffer | Where-Object { 
            ($_.Scope[0] -eq 'Environment' -and $_.ScopeName[0] -eq $EnvironmentName) -and `
            (($_.Scope -notcontains 'Computer') -or ($_.ScopeName -contains $ComputerName))
        } | Sort-Object -Property Name,ScopeName -Descending

        $hasht = @{}
        $previous = $null
        $buffer | % {
            if (-not ($_.Name -eq $previous)) {
                if ($useHashTable) {
                    $hasht.Add($_.Name, $_.Value)
                }
                else {
                    $_
                }

                $previous = $_.Name
            }
        }

        if ($useHashTable) {
            $hasht
        }
    }
}
