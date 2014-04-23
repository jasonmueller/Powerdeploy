$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
$convention = & "$here\$sut"

Describe "PackageDeploymentScriptConvention" {
	
	Setup -Dir 'Package'
	
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

    Context 'with no deployment script in the package directory' {
	
		$message = &$convention.onDeploy $context

		It "should write a message" {
			$message | should be 'No custom deployment scripts were found to execute.'
		}
    }

    Context 'with a deployment script in the root of the package directory' {
	
		Setup -File 'Package\Deploy.ps1' '$PowerDeploymentContext.Parameters | Export-CliXml TestDrive:\vars.xml'
    
		&$convention.onDeploy $context

		It "executes the custom deployment script" {
			'TestDrive:\vars.xml' | should exist
		}

		It "makes packageid variable available to the deployment script" {
			$parameters = Import-CliXml TestDrive:\vars.xml
			$parameters['PackageId'] | should be 'TestPackage'
		}

		It "makes package version available to the deployment script " {
			$parameters = Import-CliXml TestDrive:\vars.xml
			$parameters['PackageVersion'] | should be '1.2.3'
		}
		
		It "makes deployment environment name available to the deployment script " {
			$parameters = Import-CliXml TestDrive:\vars.xml
			$parameters['EnvironmentName'] | should be 'dev'
		}
		
		It "makes package deployment path available to the deployment script " {
			$parameters = Import-CliXml TestDrive:\vars.xml
			$parameters['ExtractedPackagePath'] | should be 'TestDrive:\Package'
		}

		# It "makes settings file path available to the deployment script" {
		# 	$parameters = Import-CliXml TestDrive:\vars.xml
		# 	$parameters['SettingsFilePath'].should.be('TestDrive:\Settings.ps1')
		# }
    }
}
