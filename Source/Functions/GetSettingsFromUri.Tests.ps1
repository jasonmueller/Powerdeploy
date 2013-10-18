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

Describe 'GetSettingsFromUri' {

    Context 'given an old-style settings file in the settings root folder' {

        Setup -Dir settings
        Setup -File settings\settings.pson @'
@{
    environments = @{
        oldenv = @{
            somesetting = 'some-old-value'
        }
    }
}
'@
        # URI parsing for drives requires a standard 1-letter drive name.
        New-PSDrive W FileSystem TestDrive:\ | Out-Null

        $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName oldenv

        It 'returns the requested value' {
            $settings.somesetting | should be 'some-old-value'
        }
    }

    Context 'given a settings file for the environment' {

        Setup -Dir settings\env\newenv
        Setup -File settings\env\newenv\settings.pson @'
@{
    somesetting = 'some-new-value'
}
'@
        # URI parsing for drives requires a standard 1-letter drive name.
        New-PSDrive W FileSystem TestDrive:\ | Out-Null

        $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName newenv

        It 'returns the requested value' {
            $settings.somesetting | should be 'some-new-value'
        }
    }

    Context 'given an old-style settings file in the settings root folder' {

        Setup -Dir settings
        Setup -File settings\settings.pson @'
@{
    environments = @{
        oldenv = @{
            somesetting = 'some-old-value'
        }
    }
}
'@

        Context 'and a settings file for the environment' {
            Setup -Dir settings\env\newenv
            Setup -File settings\env\newenv\settings.pson @'
@{
    somesetting = 'some-new-value'
}
'@

            # URI parsing for drives requires a standard 1-letter drive name.
            New-PSDrive W FileSystem TestDrive:\ | Out-Null

            $settings = GetSettingsFromUri -Uri W:\settings -EnvironmentName newenv

            It 'returns the requested value from the environment settings file' {
                $settings.somesetting | should be 'some-new-value'
            }
        }
    }
}
