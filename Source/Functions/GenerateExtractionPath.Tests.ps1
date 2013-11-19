$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'GenerateExtractionPath' {

    $requestedPath = 'TestDrive:\somefolder'

    Context 'with no existing directory at the requested path' {

        $result = GenerateExtractionPath $requestedPath

        It 'returns the requested path' {
            $result | should be 'TestDrive:\somefolder'
        }
    }

    Context 'with an existing directory at the requested path' {

        Setup -Dir 'somefolder'

        $result = GenerateExtractionPath $requestedPath

        It 'returns the requested path with __01 suffixed' {
            $result | should be 'TestDrive:\somefolder__01'
        }
    }


    Context 'with an existing directory (up to __49) at the requested path' {
        Setup -Dir 'somefolder'
        1..49 | % { Setup -Dir ("somefolder__{0:D2}" -f $_)  }

        $result = GenerateExtractionPath $requestedPath

        It 'returns the requested path with __50 suffixed' {
            $result | should be 'TestDrive:\somefolder__50'
        }
    }

    Context 'with existing directories up to __99 at the requested path' {
        Setup -Dir 'somefolder'
        1..99 | % { Setup -Dir ("somefolder__{0:D2}" -f $_)  }

        $result = Capture { GenerateExtractionPath $requestedPath }

        It 'throws with a message' {
            $result.message | should be 'A directory name could not be generated because all names up to __99 were allocated.'
        }
    }
}
