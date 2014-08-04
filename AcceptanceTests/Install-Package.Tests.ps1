$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Resolve-Path $here\..\_build\Powerdeploy.psd1

. $here\..\Source\Functions\New-DeploymentPackage.ps1

if (-not ((Get-Module Powerdeploy) -eq $null)) {
    Remove-Module Powerdeploy
}

Import-Module $modulePath

Describe 'Install-Package, given a test package "TestPackage1"' {

    Setup -Dir package
    Setup -Dir temp

    $testFolder = Get-PSDrive TestDrive | Select -Expand Root
    $packageFolder = Join-Path $testFolder 'package'
    $tempFolder = Join-Path $testFolder 'temp'
    $extractedFolder = Join-Path $testFolder 'extracted'
    $packageLog = Join-Path $extractedFolder 'install.log'

    $package = New-DeploymentPackage `
        -SourcePath $here\TestPackage1 `
        -PackageName SuperApp `
        -Version 1.2.3 `
        -OutputDirectoryPath $packageFolder

    Install-Package `
        -PackageArchive $package.FullName `
        -Environment 'acceptance' `
        -Variable @{ 'url' = 'http://suspendedgravity.com'; 'connection' = 'mssql://mydatabase' } `
        -DeploymentTempRoot $tempFolder `
        -PackageTargetPath $extractedFolder 

    # It 'executes pre-install scripts' {

    #     Get-Content $packageLog | Write-Host
    #     Get-Content $packageLog | Select-String 'deploy script executed' | should not be $null
    # }

    It 'executes init script' {

        Get-Content $packageLog | Select-String 'init script executed' | should not be $null
    }

    # It 'executes install script' {

    #     Get-Content $packageLog | Select-String 'install script executed' | should not be $null
    # }
}


Remove-Module Powerdeploy