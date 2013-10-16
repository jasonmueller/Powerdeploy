$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\ExecuteCommandInSession.ps1
. $here\$sut
. $here\TestHelpers.ps1

Describe 'GetPackageTempDirectoryOnTarget' {
    Context 'with no environment variable present' {
        Mock ExecuteCommandInSession { $null }

        $result = GetPackageTempDirectoryOnTarget
        
        It 'returns default packagestmp' {
            $result.LocalPath | should be 'c:\pdpackages.tmp'
        }
    }

    Context 'with environment variable set to c:\pdt' {
        Mock ExecuteCommandInSession { 'c:\pdt' }
        #[System.Environment]::SetEnvironmentVariable('PowerDeployPackageTemp', 'c:\pdt')

        $result = GetPackageTempDirectoryOnTarget
        
        It 'returns configured directory' {
            $result.LocalPath | should be 'c:\pdt'
        }
    }

    Context 'with no environment variable present on remote computer' {
        #$result = GetPackageTempDirectoryOnTarget
        
        It 'returns default packagestmp' {
           # $result | should be 'c:\packagestmp')
        }
    }
}
