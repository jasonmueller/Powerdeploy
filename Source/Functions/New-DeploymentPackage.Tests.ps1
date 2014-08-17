$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\ExpandZipArchive.ps1
. $here\..\TestHelpers.ps1

Describe 'New-DeploymentPackage, given a directory with content' {

    Setup -Dir package\content
    Setup -File package\content\placeholder.txt 'stuff'

    $pesterTestFolder = Get-PSDrive TestDrive | Select -Expand Root

    New-DeploymentPackage `
        -SourcePath $pesterTestFolder\package `
        -PackageName TestApplication `
        -Version 1.2.3 `
        -OutputDirectoryPath $pesterTestFolder

    It 'builds a package with the right name' {
        'TestDrive:\PD_TestApplication_1.2.3.zip' | should exist
    }

    It 'adds the content directory to the package' {
        ExpandZipArchive $pesterTestFolder\PD_TestApplication_1.2.3.zip $pesterTestFolder\extracted
        'TestDrive:\extracted\content\placeholder.txt' | should exist
    }
}

Describe 'New-DeploymentPackage, given a directory without content' {

    Setup -Dir package

    $pesterTestFolder = Get-PSDrive TestDrive | Select -Expand Root

    It 'throws an exception' {
        {
            New-DeploymentPackage `
                -SourcePath $pesterTestFolder\package `
                -PackageName TestApplication `
                -Version 1.2.3 `
                -OutputDirectoryPath $pesterTestFolder  
        } | should throw
    }
}
