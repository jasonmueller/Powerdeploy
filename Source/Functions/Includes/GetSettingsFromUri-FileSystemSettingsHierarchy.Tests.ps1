$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'FileSystemSettingsHierarchy -> GetSettingsFromUri' {

    Context 'given a settings folder exists with a settings file for the specified application' {

        Setup -Dir settings
        Setup -Dir settings\packages\Test.Application
        Setup -File settings\packages\Test.Application\settings.pson @'
@{
    settingname = "setting value" 
    someVariableSetting = "${env:somevariable}"
}
'@

        $settings = GetSettingsFromUri 'TestDrive:\settings' -PackageName 'Test.Application' -EnvironmentName 'TEST'

        It 'returns settings for the application' {
            $settings.settingname | should be 'setting value'
        }

        Context 'and a settings file for the specified environment with a matching variable name' {

            Setup -Dir settings\env
            Setup -Dir settings\env\TEST
            Setup -File settings\env\TEST\settings.pson @'
@{
    somevariable = "some environment value"    
}
'@

            $settings = GetSettingsFromUri 'TestDrive:\settings' -PackageName 'Test.Application' -EnvironmentName 'TEST'
            
            It 'returns replaced setting for the application' {
                $settings.someVariableSetting | should be 'some environment value'
            }
        }
    }


#     Context 'given a settings folder exists with a settings file for the specified application and environment' {

#         Setup -Dir settings
#         Setup -Dir settings\packages\Test.Application
#         Setup -File settings\packages\Test.Application\settings.TEST.pson @'
# @{
#     settingname = "setting value"    
# }
# '@

#         $settings = GetSettingsFromUri 'TestDrive:\settings' -PackageName 'Test.Application' -EnvironmentName 'TEST'

#         It 'returns settings for the application' {
#             $settings.settingname | should be 'setting value'
#         }
#     }
}

Describe 'FileSystemSettingsHierarchy -> GetSettingsFromUri' {

    Context 'given a settings folder exists with a settings file for the specified environment' {

        Setup -Dir settings
        Setup -Dir settings\env\TEST
        Setup -File settings\env\TEST\settings.pson @'
@{
    settingname = "environment setting value"    
}
'@

        $settings = GetSettingsFromUri 'TestDrive:\settings' -PackageName 'Test.Application' -EnvironmentName 'TEST'

        It 'returns settings for the environment' {
            $settings.settingname | should be 'environment setting value'
        }
    }
}

Describe 'FileSystemSettingsHierarchy -> GetSettingsFromUri' {

    Context 'given a settings folder exists with a settings file for any environment' {

        Setup -Dir settings
        Setup -Dir settings\env
        Setup -File settings\env\settings.pson @'
@{
    settingname = "global environment setting value"    
}
'@

        $settings = GetSettingsFromUri 'TestDrive:\settings' -PackageName 'Test.Application' -EnvironmentName 'TEST'

        It 'returns settings for any environment' {
            $settings.settingname | should be 'global environment setting value'
        }
    }
}