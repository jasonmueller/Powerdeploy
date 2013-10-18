$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'FileSystemHierarchy -> GetSettingsForEnvironment' {

    Context 'given a settings folder exists with a settings for the specified environment' {
        
        Setup -Dir settings\env\TEST
        Setup -File settings\env\TEST\settings.pson @'
@{
    somesetting = 'somevalue'
}
'@
    
        $settings = GetSettingsForEnvironment TestDrive:\settings -EnvironmentName TEST

        It 'returns the value of somesetting' {
            $settings.somesetting | should be 'somevalue'
        }
    }

    Context 'given a settings folder with no settings file for the specified environment' {

        Setup -Dir settings

        $settings = GetSettingsForEnvironment TestDrive:\settings -EnvironmentName TEST

        It 'returns null' {
            $settings | should be $null
        }
    }
}
