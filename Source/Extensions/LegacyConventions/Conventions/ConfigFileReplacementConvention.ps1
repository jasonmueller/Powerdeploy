# Replace variables in configuration files with environment settings.
@{
	metadata = @{
		conventionName = "Configuration file replacement"
		supportsContext = $true
	}
	
	onDeploy = {
		param (
			[Parameter(Position = 0, Mandatory = $true)]
			$PowerDeploymentContext
		)

		$contentPath = Join-Path $PowerDeploymentContext.Parameters.ExtractedPackagePath content
		$settingsPath = Join-Path $PowerDeploymentContext.Parameters.ExtractedPackagePath settings
		
		Write-Host "Replacing configs in $contentPath..."
		$configs = @(Get-ChildItem $contentPath *.config)

		$configs | ForEach-Object {
			$configPath = $_.FullName
			
			$configFilename = Split-Path $_ -Leaf
			$configDirectory = Split-Path $_.FullName -Parent
			$configFilenameNoExtension = [System.IO.Path]::GetFileNameWithoutExtension($configFilename)
			
			$replacementPath = Join-Path $settingsPath "$configFilenameNoExtension.deploy.config"
			"Locating $replacementPath..."
			if (Test-Path $replacementPath) {
				"Replacing $configPath with $replacementPath..."

				Copy-Item $replacementPath $configPath
			}
		}
	
	}
}