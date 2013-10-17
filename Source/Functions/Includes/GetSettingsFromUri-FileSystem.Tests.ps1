$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'FileSystem -> GetSettingsFromUri, ....' {

    $uri = 'http://someserver'

    $result = Capture { GetSettingsFromUri $uri 'test' }
    
    It 'throws an exception' {
        $result.message | should be 'Only filesystem based settings are currently supported.'
    }
}

# Describe 'FileSystemSingleSettingsPson -> GetSettingsFromUri, with file URI' {
#     # URI parsing for drives requires a standard 1-letter drive name.
#     New-PSDrive W FileSystem TestDrive:\ | Out-Null

#     Context 'with no settings file found in specified directory' {

#         $uri = 'file://W:\somedirectory'

#         $result = Capture { GetSettingsFromUri $uri 'test' }

#         It 'throws an result' {
#             $result.message | should be 'No settings file was found in the specified path.'
#         }
#     }

#     Context 'with settings file in specified directory with settings for specified environment' {

#         Setup -File somedirectory\Settings.pson @'
#  @{ 
#     environments = @{ 
#         test = @{ this = "that" }
#     }
# }
# '@

#         $uri = 'file://W:\somedirectory'

#         $settings = GetSettingsFromUri $uri 'test'

#         It 'returns settings from the settings file' {
#             $settings.this | should be 'that'
#         }
#     }

#     Context 'with settings file in specified directory with no settings for specified environment' {

#         Setup -File somedirectory\Settings.pson @'
# @{ 
#     environments = @{ 
#         dev = @{ this = "that" }
#     }
# }
# '@

#         $uri = 'file://W:\somedirectory'

#         $result = Capture { GetSettingsFromUri $uri 'test' }

#         It 'throws with a meaningful message' {
#             $result.message | should be 'No environment settings for the environment ''test'' were found in the settings file.'
#         }
#     }

#     Context 'with unparsable settings file' {

#         Setup -File somedirectory\Settings.pson @'
# @{
#     foojibber  '"
# '@

#         $uri = 'file://W:\somedirectory'
#         $result = Capture { GetSettingsFromUri $uri 'test' }

#         It 'throws with a meaningful message' {
#             $result.message | should be 'The settings file could not be parsed.  Ensure that it is valid PowerShell.'
#         }
#     }
# }

# Describe 'FileSystemSingleSettingsPson -> GetSettingsFromUri, with computer name' {
#     # URI parsing for drives requires a standard 1-letter drive name.
#     New-PSDrive W FileSystem TestDrive:\ | Out-Null

#     Context 'with computer settings specified for the computer' {

#         Setup -File somedirectory\Settings.pson @'
#  @{ 
#     environments = @{ 
#         test = @{
#             this = "that"
#             that = "theother"
#             Overrides = @{
#                 Computers = @{
#                     ROVER1 = @{
#                         this = 'mars'
#                         what = 'doesntmatter'
#                     }
#                 }
#             }
#         }
#     }
# }
# '@

#         $uri = 'file://W:\somedirectory'

#         $settings = GetSettingsFromUri $uri 'test' 'ROVER1'

#         It 'returns settings for the environment for a key that is not in the computers overrides' {
#             $settings.that | should be 'theother'
#         }

#         It 'returns settings for the computer for a key that is in the computers overrides' {
#             $settings.this | should be 'mars'
#         }

#         It 'does not return settings in the computer overrides that is not in the parent environment' {
#             ($settings['what'] -eq $null) | should be $true
#         }

#         It 'removes the overrides section from the configuration' {
#             ($settings['Overrides'] -eq $null) | should be $true
#         }
#     }

#     Context 'with no computer settings sepcified for the computer' {
#         Setup -File somedirectory\Settings.pson @'
#  @{ 
#     environments = @{ 
#         test = @{
#             this = "that"
#             that = "theother"
#             Overrides = @{ Computers = @{} }
#         }
#     }
# }
# '@

#         $uri = 'file://W:\somedirectory'

#         $settings = GetSettingsFromUri $uri 'test' 'ROVER1'

#         It 'returns settings for the environment' {
#             $settings.that | should be 'theother'
#         }

#         It 'removes the overrides section from the configuration' {
#             ($settings['Overrides'] -eq $null) | should be $true
#         }
#     }
# }

# Describe 'FileSystemSingleSettingsPson -> GetSettingsFromUri, with role name' {
#     # URI parsing for drives requires a standard 1-letter drive name.
#     New-PSDrive W FileSystem TestDrive:\ | Out-Null

#     Context 'with role settings specified for the role' {

#         Setup -File somedirectory\Settings.pson @'
#  @{ 
#     environments = @{ 
#         test = @{
#             this = "that"
#             that = "theother"
#             Overrides = @{
#                 Roles = @{
#                     WEB = @{
#                         this = 'mars'
#                         what = 'doesntmatter'
#                     }
#                 }
#             }
#         }
#     }
# }
# '@

#         $uri = 'file://W:\somedirectory'

#         $settings = GetSettingsFromUri $uri 'test' 'ROVER1' 'WEB'

#         It 'returns settings for the environment for a key that is not in the roles overrides' {
#             $settings.that | should be 'theother'
#         }

#         It 'returns settings for the role for a key that is in the roles overrides' {
#             $settings.this| should be 'mars'
#         }

#         It 'does not return settings in the roles overrides that is not in the parent environment' {
#             ($settings['what'] -eq $null) | should be $true
#         }

#         It 'removes the overrides section from the configuration' {
#             ($settings['Overrides'] -eq $null) | should be $true
#         }
#     }

#     Context 'with no role settings specified for the role' {
#         Setup -File somedirectory\Settings.pson @'
#  @{ 
#     environments = @{ 
#         test = @{
#             this = "that"
#             that = "theother"
#             Overrides = @{ Roles = @{} }
#         }
#     }
# }
# '@

#         $uri = 'file://W:\somedirectory'

#         $settings = GetSettingsFromUri $uri 'test' 'ROVER1' 'WEB'

#         It 'returns settings for the environment' {
#             $settings.that | should be 'theother'
#         }

#         It 'removes the overrides section from the configuration' {
#             ($settings['Overrides'] -eq $null) | should be $true
#         }
#     }
# }