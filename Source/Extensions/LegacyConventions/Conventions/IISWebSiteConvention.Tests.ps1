$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$convention = & "$here\$sut"

function Create-MockWebsite ($Name, $Properties) {
    $sitePath = "iis:\sites\$Name"

    # We need to Invoke-Expression this in order to get the expression to use our incoming
    # parameters.  Otherwise, they get evaluated when the Mock is called and the parameters
    # are out of scope.
    Mock Test-Path { return $true } -ParameterFilter (Invoke-Expression "{ `$Path -eq '$sitePath' }")
}

function Create-MockWebsiteChildren ($WebsiteName, $Children) {
    $sitePath = "iis:\sites\$WebsiteName"
#Invoke-Expression "{ return $Children }"
    Mock Get-ChildItem (Invoke-Expression "{ return $Children }") -ParameterFilter (Invoke-Expression "{ `$Path -eq '$sitePath' }")
}

function Create-MockIisInstallation ($Version = $null) {
    if ($Version -eq $null) {
        Mock Test-Path { return $false } -ParameterFilter { $Path -eq 'HKLM:\software\microsoft\InetStp' }
    }
    else {
        Mock Test-Path { return $true } -ParameterFilter { $Path -eq 'HKLM:\software\microsoft\InetStp' }
        Mock Get-ItemProperty (Invoke-Expression "{ return @{ MajorVersion = $Version } }") -ParameterFilter { $Path -eq "HKLM:\software\microsoft\InetStp" }
    }
}

Describe 'IIS Website Convention' {
    $context = @{
        Parameters = @{
            PackageId = 'TestPackage'
            PackageVersion = '1.2.3'
            EnvironmentName = 'dev'
            DeploymentFilesPath = 'TestDrive:\deploymenttemp'
            ExtractedPackagePath = 'TestDrive:\Package'
        }
        Settings = @{
        }
    }

    Context 'given IIS is not installed' {
        Create-MockIisInstallation -Version $null

        Mock Write-Host { } -Verifiable -ParameterFilter { $Object -like 'IIS installation was not found. '`
            + 'The convention will be skipped.' }
        Mock Set-ItemProperty { }

        $message = &$convention.onDeploy $context


        It 'displays a skipping message' {
            Assert-VerifiableMocks
        }

        It 'does not update any website properties' {
            Assert-MockCalled Set-ItemProperty -Times 0
        }
    }

    # Context 'given IIS 6.X is installed' {
    #     Mock Test-Path { return $true } -ParameterFilter { $Path -eq 'HKLM:\software\microsoft\InetStp' }
    #     Mock Get-ItemProperty { return @{ MajorVersion = 6 } } -ParameterFilter { $Path -eq "HKLM:\software\microsoft\InetStp" }

    #     $message = &$convention.onDeploy $context

    #     It 'does something' {

    #     }
    # }

    Context 'given IIS 7.X is installed with a website named the same as the package' {

        Create-MockIisInstallation -Version 7
        Create-MockWebsite -Name testpackage

        Mock Set-ItemProperty { }
        Mock Get-ChildItem { } -ParameterFilter { $Path -eq 'iis:\sites\testpackage' }

        function Load-WebAdministration { }
        function Unload-WebAdministration { }

        $message = &$convention.onDeploy $context

        It 'updates the website home directory to point to the new content path' {
            Assert-MockCalled Set-ItemProperty -ParameterFilter { $Path -eq 'iis:\sites\testpackage' -and $Value -eq 'TestDrive:\Package\content' }
        }

        # Context 'and an application in the website that is pointed to a directory containing package content' {
        #     #Mock Get-ChildItem { return @{ NodeType = 'application'; Name = 'subapp' }} -ParameterFilter { $Path -eq 'iis:\sites\testpackage' }
        #     Mock Get-ChildItem { return @(@{ NodeType = 'application'; Name = 'subapp' }) } -ParameterFilter { $Path -eq 'iis:\sites\testpackage' }
        #     # Create-MockWebsiteChildren -WebsiteName testpackage -Children @(
        #     #     New-Object psobject -Property @{
        #     #         NodeType = 'application'
        #     #         Name = 'subapp'
        #     #     }
        #     # )

        #     $message = &$convention.onDeploy $context
            
        #     It 'updates the application content path' {
        #         Assert-MockCalled Set-ItemProperty -ParameterFilter { $Path -eq 'iis:\sites\testpackage\subapp' -and $Value -eq 'TestDrive:\Package\content' }
        #     }
        # }
    }


    Context 'given IIS 7.X is installed with a website named the same as the package and environment' {
        
        Create-MockIisInstallation -Version 7
        Create-MockWebsite -Name 'testpackage-dev'

        Mock Set-ItemProperty { }
        Mock Get-ChildItem { }

        function Load-WebAdministration { }
        function Unload-WebAdministration { }

        $message = &$convention.onDeploy $context

        It 'updates the website home directory to point to the new content path' {
            Assert-MockCalled Set-ItemProperty -ParameterFilter { $Path -eq 'iis:\sites\testpackage-dev' -and $Value -eq 'TestDrive:\Package\content' }
        }
    }
}
