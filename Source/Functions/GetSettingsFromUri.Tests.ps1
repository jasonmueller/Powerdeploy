$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\TestHelpers.ps1

Describe 'GetSettingsFromUri, with non-file URI' {

    $uri = 'http://someserver'

    $result = Capture { GetSettingsFromUri $uri 'test' }
    
    It 'throws an exception' {
        $result.message | should be 'Only filesystem based settings are currently supported.'
    }
}
