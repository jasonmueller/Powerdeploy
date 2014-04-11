$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. $here\..\MimicModule.Tests.ps1
. $here\..\TestHelpers.ps1

Describe 'Invoke-Powerdeploy, with a package archive' {

    Context 'given the archive doesn''t exist' {
        Setup -Dir pdtemp

        $result = Capture { 
            Invoke-Powerdeploy `
                -PackageArchive 'testdrive:\somepackage_1.2.3.zip' `
                -Environment 'production' 
        }

        It 'aborts with an error' {
            $result | should not be $null
            $result | select -expand message | should be 'The package specified does not exist: testdrive:\somepackage_1.2.3.zip'
        }
    }
}

