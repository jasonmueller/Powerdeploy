$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

function New-DeploymentVariable {
    [CmdletBinding()]
    param (
        [string]
        $Name,
        [string]
        $Value,
        [string[]]
        $Scope,
        [string[]]
        $ScopeName
    )

    # if (-not ($Scope -is [Array])) {
    #     $Scope = @($Scope)
    # }

    New-Object PSObject -Property @{
        Type = 'NameValue'
        Name = $Name
        Value = $Value
        Scope = $Scope
        ScopeName = $ScopeName
    }
}

Describe 'Resolve-ConfigurationVariable, given variables for multiple environments and computers' {

    $variables = @()
    $variables += New-DeploymentVariable -Name 'blah' -Value 'blah' -Scope 'Environment' -ScopeName 'prod'
    $variables += New-DeploymentVariable -Name 'blah' -Value 'blah2' -Scope 'Environment' -ScopeName 'prod2'
    $variables += New-DeploymentVariable -Name 'keep' -Value 'this' -Scope 'Environment' -ScopeName 'prod2'
    $variables += New-DeploymentVariable -Name 'blah' -Value 'blah2-rover' -Scope 'Environment','Computer' -ScopeName 'prod2','rover1'

    Context 'with an environment and computer having no overrides' {

        $result = $variables | Resolve-ConfigurationVariable -Environment prod -ComputerName rover1

        It 'returns only variables for the specified environment' {
            $result | Measure-Object | Select -expand Count | should be 1
            $result | ? {
                $_.Name -eq 'blah' -and `
                $_.Value -eq 'blah'
            } | Measure-Object | Select -expand Count | should be 1
        }
    }

    Context 'with an environment and computer having overrides' {

        $result = $variables | Resolve-ConfigurationVariable -Environment prod2 -ComputerName rover1

        It 'returns one value for each variable in the environment' {
            $result | Measure-Object | Select -expand Count | should be 2
        }

        It 'returns variables for the specified environment that have no overrides' {
            $result | ? {
                $_.Name -eq 'keep' -and `
                $_.Value -eq 'this'
            } | Measure-Object | Select -expand Count | should be 1
        }
        
        It 'returns computer variables for variables that have overrides' {
            $result | ? {
                $_.Name -eq 'blah' -and `
                $_.Value -eq 'blah2-rover'
            } | Measure-Object | Select -expand Count | should be 1
        } 
    }

    Context 'with an environment and computer having overrides, as a hashtable' {

        $result = $variables | Resolve-ConfigurationVariable -Environment prod2 -ComputerName rover1 -AsHashTable

        It 'returns one value for each variable in the environment' {
            $result.Keys | Measure-Object | Select -expand Count | should be 2
        }

        It 'returns variables for the specified environment that have no overrides' {
            $result.keep | should be 'this'
        }
        
        It 'returns computer variables for variables that have overrides' {
            $result.blah | should be 'blah2-rover'
        } 
    }
}
