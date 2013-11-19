$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut
. $here\..\TestHelpers.ps1

Describe 'BuildDeploymentContext' {

    $context = BuildDeploymentContext 'Test.Package' '1.2.3' 'TestDrive:\deploytemp' 'ENV' 'TestDrive:\packagefiles'

    It 'adds the package id to the context' {
        $context.Parameters.PackageId | should be 'Test.Package'       
    }

    It 'adds the package version to the context' {
        $context.Parameters.PackageVersion | should be '1.2.3'       
    }

    It 'adds the environment name to the context' {
        $context.Parameters.EnvironmentName | should be 'ENV'        
    }

    It 'adds the deployment path to the context' {
        $context.Parameters.DeploymentFilesPath | should be 'TestDrive:\deploytemp'        
    }

    It 'adds the final extracted package path to the context' {
        $context.Parameters.ExtractedPackagePath | should be 'TestDrive:\packagefiles'
    }

    Context 'with no settings files' {

        $context = BuildDeploymentContext 'Test.Package' '1.2.3' 'TestDrive:\deploytemp' 'ENV' 'TestDrive:\extracted'

        It 'adds empty settings to the context' {
            ($context.Settings -eq $null) | should be $false
            $context.Settings.Keys.Count | should be 0
        }
    }

    Context 'with settings file in deployment directory settings' {

        Setup -File deploytemp\settings\Settings.pson '@{ somesetting = "goodvalue" }'

        $context = BuildDeploymentContext 'Test.Package' '1.2.3' 'TestDrive:\deploytemp' 'ENV' 'TestDrive:\extracted'

        It 'adds settings from settings file to context' {
            $context.Settings.somesetting | should be 'goodvalue'
        }
    }


    Context 'with old-style settings file in package settings directory and settings file in deployment settings directory' {

        Setup -File deploytemp\settings\Settings.pson '@{ somesetting = "goodvalue" }'

        Setup -File extracted\settings\Settings.ps1 @"
@{ 
    environments = @{
        dev = @{
            somesetting = 'goodvaluedev'
        }
        qa = @{
            somesetting = 'goodvalueqa'
        }
    }
}
"@

        $context = BuildDeploymentContext 'Test.Package' '1.2.3' 'TestDrive:\deploytemp' 'dev' 'TestDrive:\extracted'

        It 'uses settings from the package settings directory' {
            $context.Settings.somesetting | should be 'goodvaluedev'
        }
    }

    Context 'with old-style settings file in package settings directory' {
 
        Setup -File extracted\settings\Settings.ps1 @"
@{ 
    environments = @{
        dev = @{
            somesetting = 'goodvaluedev'
        }
        qa = @{
            somesetting = 'goodvalueqa'
        }
    }
}
"@

        $context = BuildDeploymentContext 'Test.Package' '1.2.3' 'TestDrive:\deploytemp' 'qa' 'TestDrive:\extracted'

        It 'adds settings from settings file to context' {
            $context.Settings.somesetting | should be 'goodvalueqa'
        }
    }

    Context 'with old-style settings file not containing current environment in package settings directory' {
 
        Setup -File extracted\settings\Settings.ps1 @"
@{ 
    environments = @{
        dev = @{
            somesetting = 'goodvaluedev'
        }
        qa = @{
            somesetting = 'goodvalueqa'
        }
    }
}
"@

        $result = (Capture { BuildDeploymentContext 'Test.Package' '1.2.3' 'TestDrive:\deploytemp' 'foo' 'TestDrive:\extracted' })

        It 'throws with a message' {
            $result.message | should be 'No environment settings section was found in the settings file for the environment ''foo''.'
        }
    }
}