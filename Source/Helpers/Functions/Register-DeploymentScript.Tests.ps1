$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\Common.Tests.ps1
. $here\..\TestHelpers.ps1

Describe 'Register-DeploymentScript, with a pre-installation script' {

    Register-DeploymentScript -Pre -Phase Install -Script {'hello'}

    It 'registers the script' {
        Get-RegisteredDeploymentScript -Pre -Phase Install | should be "'hello'"
    }
}

Describe 'Register-DeploymentScript, with invalid phase' {

    $exception = Capture { Register-DeploymentScript -Pre -Phase Mystery -Script {'hello'} }

    It 'throws' {
        $exception.ErrorRecord.FullyQualifiedErrorId | should be 'ValidateSetFailure'
    }
}

Describe 'Invoke-RegisteredDeploymentScript, with a script' {
    $global:pester_pd_test_irds_ran = $false

    Invoke-RegisteredDeploymentScript -Script { $global:pester_pd_test_irds_ran = $true }

    It 'executes the script' {
         $global:pester_pd_test_irds_ran | should be $true
    }
}
