$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\New-ConfigurationVariable.ps1
. $here\..\TestHelpers.ps1

Describe 'Add-ConfigurationVariable with a variable as input' {

    $variables = @()
    $variables += New-ConfigurationVariable -Name 'blah' -Value 'blah' -Scope 'Environment' -ScopeName 'prod'

    $variables | Add-ConfigurationVariable -Name 'blah2' -Value 'value2' -Scope 'Environment' -ScopeName 'prod' | Set-Variable outputVariables

    It 'outputs two variables' {
        $outputVariables | Measure-Object | Select -Expand Count | should be 2
    }

    It 'outputs the input variable' {
        $outputVariables | ? {
            $_.Name -eq 'blah' -and `
            $_.Value -eq 'blah' -and `
            $_.Scope -contains 'Environment' -and `
            $_.ScopeName -contains 'prod'
        } | Measure-Object | Select -Expand Count | should be 1 
    }

    It 'outputs the new variable' {
        $outputVariables | ? {
            $_.Name -eq 'blah2' -and `
            $_.Value -eq 'value2' -and `
            $_.Scope -contains 'Environment' -and `
            $_.ScopeName -contains 'prod'
        } | Measure-Object | Select -Expand Count | should be 1 
    }
}
