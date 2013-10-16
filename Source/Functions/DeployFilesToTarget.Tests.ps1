$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. $here\$sut

Describe 'DeployFilesToTarget' {

    Context 'with settings uri' {
        function GetSettingsFromUri($a) { @{ "this" = "that"; "complex" = 'p@$$w0rd' } }

        Mock Copy-Item { }

        DeployFilesToTarget TestDrive:\packagetemp b c -Settings @{ "this" = "that"; "complex" = 'p@$$w0rd' }

        It 'stores the settings retrieved from the URI to the settings.pson file in the target directory' {
            $settings = Invoke-Expression (Get-Content TestDrive:\packagetemp\settings\Settings.pson | Out-String)
            $settings.this | should be 'that'
        }

        It 'correctly handles $ characters' {
            $settings = Invoke-Expression (Get-Content TestDrive:\packagetemp\settings\Settings.pson | Out-String)
            $settings.complex | should be 'p@$$w0rd'
       }
    }

    Context 'without settings' {
        
        Mock Copy-Item { }

        DeployFilesToTarget TestDrive:\packagetemp b c

        It 'succeeds' {

        }
    }
}