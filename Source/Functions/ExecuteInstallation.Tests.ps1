$global:TestContext = @{} 
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerModulePath = "$here\..\Helpers\Functions\DeploymentContext.ps1"
. $here\..\MimicModule.Tests.ps1
. $installerModulePath

Describe 'ExecuteInstallation' {
    $fakeContext =  @{
        Parameters = @{
            PackageId = 'fuzzy-bunny'
            PackageVersion = '9.3.1'
            EnvironmentName = 'prod-like'
            ExtractedPackagePath = 'testdrive:\package-target'
        }
        Settings = @{
            setting1 = 'value1'
        }
    }

    Mock RunConventions { $global:TestContext.conventionsHadContext = $global:TestContext.contextCalled }
    Mock Set-DeploymentContext { $global:TestContext.contextCalled = $true } 
    #Mock Import-Module { } -ParameterFilter { $Name -like '*Installer.psm1' }
    Mock BuildDeploymentContext { $fakeContext } -ParameterFilter { $DeploymentSourcePath -eq 'testdrive:\pdtemp'}

    ExecuteInstallation `
        -PackageName 'fuzzy-bunny' `
        -PackageVersion '9.3.1' `
        -EnvironmentName 'prod-like' `
        -DeployedFolderPath 'testdrive:\package-target' `
        -DeploymentSourcePath 'testdrive:\pdtemp'

    It 'configures the deployment context' {
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $EnvironmentName -eq 'prod-like' }
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $DeployedFolderPath -eq 'testdrive:\package-target' }
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $PackageName -eq 'fuzzy-bunny' }
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $PackageVersion -eq '9.3.1' }
    }

    It 'configures the deployment context settings' {
        Assert-MockCalled Set-DeploymentContext -ParameterFilter { $Variables.setting1 -eq 'value1' }
    }

    It 'runs conventions with old-style context' {
        Assert-MockCalled RunConventions -ParameterFilter { 
            $deploymentContext.Parameters.PackageId -eq 'fuzzy-bunny' `
            -and $deploymentContext.Parameters.PackageVersion -eq '9.3.1' `
            -and $deploymentContext.Parameters.EnvironmentName -eq 'prod-like' `
            -and $deploymentContext.Parameters.ExtractedPackagePath -eq 'testdrive:\package-target' `
            -and $deploymentContext.Settings.setting1 -eq 'value1'
        }
    }

    It 'makes context available to conventions' {
        $global:TestContext.conventionsHadContext | should be $true
    }

}

Describe 'ExecuteInstallation (as bdd)' {
    
    $global:pester_pd_test_initialization_executed = $false
    $global:pester_pd_test_initialization_context_value = $null
    $global:pester_pd_test_preinstall_executed = $false

    Setup -Dir 'package-target'
    Setup -Dir 'package-target\content'
    Setup -Dir 'package-target\deploy'

    Setup -File 'package-target\deploy\initialize.ps1' @'
$global:pester_pd_test_initialization_executed = $true

Register-DeploymentScript -Pre -Phase Install -Script { $global:pester_pd_test_preinstall_executed = $true; $global:pester_pd_test_initialization_context_value = Get-DeploymentPackageName }
'@

    ExecuteInstallation `
        -PackageName 'fuzzy-bunny' `
        -PackageVersion '9.3.1' `
        -EnvironmentName 'prod-like' `
        -DeployedFolderPath 'testdrive:\package-target' `
        -DeploymentSourcePath 'testdrive:\pdtemp'

    It 'executes the package initialization script' {
         $global:pester_pd_test_initialization_executed | should be $true
    }

    It 'executes pre-Install scripts' {
        $global:pester_pd_test_preinstall_executed | should be $true
    }

    It 'supplies the deployment context to the initialization script' {
        $global:pester_pd_test_initialization_context_value | should be 'fuzzy-bunny'
    }    
}