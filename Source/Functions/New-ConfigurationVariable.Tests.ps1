$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'New-ConfigurationVariable' {

    $variable = New-ConfigurationVariable -Name 'blah' -Value 'blah' -Scope 'Environment' -ScopeName 'prod'

    It 'outputs the new variable' {
        $variable | ? {
            $_.Name -eq 'blah' -and `
            $_.Value -eq 'blah' -and `
            $_.Scope -contains 'Environment' -and `
            $_.ScopeName -contains 'prod'
        } | Measure-Object | Select -Expand Count | should be 1 
    }
}
