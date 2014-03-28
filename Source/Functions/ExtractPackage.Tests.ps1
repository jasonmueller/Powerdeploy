$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1
. $here\..\Functions\ExpandZipArchive.ps1

Describe 'ExtractPackage' {

    # 7zip can't use PowerShell drives.
    $extractionPath = Join-Path (Get-PSDrive TestDrive | Select -Expand Root) 'extracted'

    Context 'given a .zip file' {

    	$archivePath = Resolve-Path $here\..\Examples\ExtractionTest.zip

        ExtractPackage $archivePath $extractionPath

        It 'extracts the package' {
            Test-Path 'TestDrive:\extracted\dir1' | should be $true
            Test-Path 'TestDrive:\extracted\dir1\file1.txt' | should be $true
            Test-Path 'TestDrive:\extracted\dir1\file2.txt' | should be $true
            Test-Path 'TestDrive:\extracted\dir1\dir1_1' | should be $true
            Test-Path 'TestDrive:\extracted\dir1\dir1_1\file1_1.txt' | should be $true
            Test-Path 'TestDrive:\extracted\dir2' | should be $true
            Test-Path 'TestDrive:\extracted\dir2\file1.txt' | should be $true
        }
    }
}