$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\MimicModule.Tests.ps1

Describe 'Install-Package' {

    Setup -Dir pdtemp

    Mock Import-Pscx { }
    Mock ExtractPackage { }
    Mock ExecuteInstallation { }

    Install-Package `
        -PackageArchive 'somepackage_1.2.3.zip' `
        -Environment 'production' `
        -DeploymentTempRoot testdrive:\pdtemp `
        -PackageTargetPath testdrive:\deploytome

    It 'starts installation' {
        Assert-MockCalled ExecuteInstallation -ParameterFilter { `
            $PackageName -eq 'somepackage' `
            -and $PackageVersion -eq '1.2.3' `
            -and $EnvironmentName -eq 'production' `
            -and $DeployedFolderPath -eq 'testdrive:\deploytome' `
            -and $DeploymentSourcePath -eq 'testdrive:\pdtemp'
        }
    }
}
