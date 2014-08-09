$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

function Have($value, $expected) {

        $propertiesToTest = $expected | select -expand Keys
        Write-Host $propertiesToTest
        $value | convertto-json | write-host
        $expected | convertto-json | write-host
        $value | Compare-Object `
            -ReferenceObject (New-Object PSObject -Property $expected) `
            -Property $propertiesToTest | Set-Variable differences
            #-ExcludeDifferent `
            #-IncludeEqual `

        $differences -eq $null
}

Describe 'Get-ConfigurationVariable' {

    Context 'with a non-file URI' {

        $uri = 'http://someserver'

        $result = Capture { Get-ConfigurationVariable -SettingsPath $uri }
        
        It 'throws an exception' {
            $result.message | should be 'Only filesystem based settings are currently supported.'
        }
    }

    # URI parsing for drives requires a standard 1-letter drive name.
    

    Setup -Directory Placeholder
    New-PSDrive W FileSystem TestDrive:\ | Out-Null

    Context 'with a file URI, given no settings file found in specified directory' {

        $uri = 'file://W:\somedirectory'

        $result = Capture { Get-ConfigurationVariable -SettingsPath $uri }

        It 'throws an result' {
            $result.message | should be 'No settings file was found in the specified path.'
        }
    }


    Context 'with a file URI, given settings file in specified directory' {# with settings for environments and environment computers' {

        Setup -File somedirectory\Settings.pson @'
 @{ 
    environments = @{ 
        test = @{
            this = "that-test"
        }
        prod = @{
            that = "this"
        }
    }
}
'@

        $uri = 'file://W:\somedirectory'

        $settings = Get-ConfigurationVariable -SettingsPath $uri

        It 'returns all settings for all environments' {
            $settings | Measure-Object | Select -Expand Count | should be 2
            $settings | ? {
                $_.Name -eq 'this' -and `
                $_.Value -eq 'that-test' -and `
                $_.Scope -contains 'Environment' -and `
                $_.ScopeName -contains 'test'
            } | Measure-Object | Select -Expand Count | should be 1 
            $settings | ? {
                $_.Name -eq 'that' -and `
                $_.Value -eq 'this' -and `
                $_.Scope -contains 'Environment' -and `
                $_.ScopeName -contains 'prod'
            } | Measure-Object | Select -Expand Count | should be 1 
        }
    }

    Context 'with a file URI, given settings file in specified directory and a matching computer override' {

        Setup -File somedirectory\Settings.pson @'
 @{ 
    environments = @{ 
        prod = @{
            this = "that"
            that = "this"
            Overrides = @{
                            Computers = @{
                                ROVER1 = @{
                                    this = 'mars'
                                    what = 'doesntmatter'
                                }
                            }
                        }
        }
    }
}
'@

        $uri = 'file://W:\somedirectory'

        $settings = Get-ConfigurationVariable -SettingsPath $uri

        It 'returns environment-scoped settings' {
            $settings | ? {
                $_.Name -eq 'this' -and `
                $_.Value -eq 'that' -and `
                $_.Scope -contains 'Environment' -and `
                $_.ScopeName -contains 'prod'
            } | Measure-Object | Select -Expand Count | should be 1 
            $settings | ? {
                $_.Name -eq 'that' -and `
                $_.Value -eq 'this' -and `
                $_.Scope -contains 'Environment' -and `
                $_.ScopeName -contains 'prod'
            } | Measure-Object | Select -Expand Count | should be 1 
        }

        It 'returns environmentcomputer-scoped settings' {
            $settings | ? {
                $_.Name -eq 'this' -and `
                $_.Value -eq 'mars' -and `
                ($_.Scope -contains 'Environment' -and $_.Scope -contains 'Computer') -and `
                ($_.ScopeName -contains 'prod' -and $_.ScopeName -contains 'ROVER1')
            } | Measure-Object | Select -Expand Count | should be 1         
        }

        # It 'returns only computer overrides that have enviroment-scoped settings' {
        #     $settings | Measure-Object | Select -Expand Count | should be 3
        # }
    }

    Context 'given settings file in specified directory and a matching computer override for multiple environments' {

        Setup -File somedirectory\Settings.pson @'
 @{ 
    environments = @{
        test = @{
            this = "that-test"
            that = "this-test"
            Overrides = @{
                            Computers = @{
                                ROVER1 = @{
                                    this = 'mars-test'
                                }
                            }
                        }
        }
        prod = @{
            this = "that"
            Overrides = @{
                            Computers = @{
                                ROVER1 = @{
                                    this = 'mars'
                                }
                                ROVER2 = @{
                                    this = 'mars2'
                                }
                            }
                        }
        }
    }
}
'@

        $uri = 'file://W:\somedirectory'

        # Context 'with an environment name' {

        #     $settings = Get-ConfigurationVariable -SettingsPath $uri -Environment 'prod'

        #     It 'returns only settings scoped to the environment' {
        #         $settings | Measure-Object | Select -Expand count | should be 3
        #         $settings | ? {
        #             $_.Name -eq 'this' -and `
        #             $_.Value -eq 'that' -and `
        #             ($_.Scope -contains 'Environment') -and `
        #             ($_.ScopeName -contains 'prod')
        #         } | Measure-Object | Select -Expand Count | should be 1  
        #         $settings | ? {
        #             $_.Name -eq 'this' -and `
        #             $_.Value -eq 'mars' -and `
        #             ($_.Scope -contains 'Environment' -and $_.Scope -contains 'Computer') -and `
        #             ($_.ScopeName -contains 'prod' -and $_.ScopeName -contains 'ROVER1')
        #         } | Measure-Object | Select -Expand Count | should be 1  
        #         $settings | ? {
        #             $_.Name -eq 'this' -and `
        #             $_.Value -eq 'mars2' -and `
        #             ($_.Scope -contains 'Environment' -and $_.Scope -contains 'Computer') -and `
        #             ($_.ScopeName -contains 'prod' -and $_.ScopeName -contains 'ROVER2')
        #         } | Measure-Object | Select -Expand Count | should be 1  
        #     }
        # }

        # Context 'with an environment and computer name' {

        #     $settings = Get-ConfigurationVariable -SettingsPath $uri -Environment 'prod' -Computer 'rover1'

        #     It 'returns only settings scoped to the environment or to the environment and computer' {
        #         $settings | Measure-Object | Select -Expand count | should be 2
        #         $settings | ? {
        #             $_.Name -eq 'this' -and `
        #             $_.Value -eq 'that' -and `
        #             ($_.Scope -contains 'Environment') -and `
        #             ($_.ScopeName -contains 'prod')
        #         } | Measure-Object | Select -Expand Count | should be 1  
        #         $settings | ? {
        #             $_.Name -eq 'this' -and `
        #             $_.Value -eq 'mars' -and `
        #             ($_.Scope -contains 'Environment' -and $_.Scope -contains 'Computer') -and `
        #             ($_.ScopeName -contains 'prod' -and $_.ScopeName -contains 'ROVER1')
        #         } | Measure-Object | Select -Expand Count | should be 1  
        #     }
        # }
    }

}
