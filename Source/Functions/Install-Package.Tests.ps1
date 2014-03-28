$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\MimicModule.Tests.ps1

Describe 'Install-Package' {

    Setup -Dir pdtemp

    Mock ExtractPackage { }
    Mock ExecuteInstallation { }

    Install-Package `
        -PackageArchive 'somepackage_1.2.3.zip' `
        -Environment 'production' `
        -DeploymentTempRoot testdrive:\pdtemp `
        -PackageTargetPath testdrive:\deploytome `
        -PostInstallScript { $PowerdeployDeploymentParameters | ConvertTo-Json | Out-File testdrive:\params.json }

    It 'starts installation' {
        Assert-MockCalled ExecuteInstallation -ParameterFilter { `
            $PackageName -eq 'somepackage' `
            -and $PackageVersion -eq '1.2.3' `
            -and $EnvironmentName -eq 'production' `
            -and $DeployedFolderPath -eq 'testdrive:\deploytome' `
            -and $DeploymentSourcePath -eq 'testdrive:\pdtemp'
        }
    }

    It 'executes post install script' {
        Test-Path testdrive:\params.json | should be $true
    }

    It 'makes deployment parameters available to install script' {
        $params = Get-Content testdrive:\params.json -Raw | ConvertFrom-Json

        $params.PackageName | should be 'somepackage'
        $params.PackageVersion | should be '1.2.3'
        $params.EnvironmentName | should be 'production'
        $params.DeployedFolderPath | should be 'testdrive:\deploytome'
    }
}
