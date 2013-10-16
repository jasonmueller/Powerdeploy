function BuildDeploymentContext {
	param (
		$PackageId,
		$PackageVersion,
		$DeploymentSourcePath,
		$EnvironmentName,
		$ExtractedPackagePath
	)

	$packageSettingsPath = "$ExtractedPackagePath\settings\Settings.ps1"
	$deploymentSettingsPath = "$DeploymentSourcePath\settings\Settings.pson"

	$settingsFile = $packageSettingsPath
	if (!(Test-Path $settingsFile)) {
		Write-Verbose "Package settings were not found.  Deployment settings will be used if available."
		$settingsFile = $deploymentSettingsPath
	}
	else {
		if (Test-Path $deploymentSettingsPath) {
			Write-Verbose "Settings were found for both the deployment and the package.  Package settings will be used.  If this package should be using centralized deployment settings, remove the Settings.ps1 file from the settings folder in the package."
		}
	}

	Write-Verbose "Attempting to load settings from '$settingsFile'..."

	if (Test-Path $settingsFile) {
		$settings = Invoke-Expression (Get-Content $settingsFile | Out-String)
		if ($settings.environments -ne $null) {
			if ($settings.environments[$EnvironmentName] -eq $null) {
				throw "No environment settings section was found in the settings file for the environment '$EnvironmentName'."
			}
			$settings = $settings.environments[$EnvironmentName]
		}
	}
	else {
		$settings = @{ }
	}

	@{
	    Parameters = @{
	    	PackageId = $PackageId
	    	PackageVersion = $PackageVersion
	    	EnvironmentName = $EnvironmentName
		    DeploymentFilesPath = $DeploymentSourcePath
		    ExtractedPackagePath = $ExtractedPackagePath
		    # SettingsFilePath = $settingsFile
	    }
	    Settings = $settings
	}
}