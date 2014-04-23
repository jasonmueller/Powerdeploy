# Provides support for hot deployments of Windows services
# Given a Windows service named the same as the package
#       with or without the environment name separated by a '-'
#   and package files deployed to a content folder
#   and the service process exists in the root of the content folder
# When  the convention runs
# Then  the executable binary path for the service will 
#       be updated to the location of the new version's
#       content files
#   and the service will be restarted
@{
	metadata = @{
		conventionName = "Windows service convention"
	}
	
	onDeploy = {
		param (
			[Parameter(Mandatory = $true)]
			$PowerDeploymentContext
		)
		
		$packageId = $PowerDeploymentContext.Parameters.PackageId
		$sourcePath = $PowerDeploymentContext.Parameters.ExtractedPackagePath
		$environmentName = $PowerDeploymentContext.Parameters.EnvironmentName

		Write-Host "Running Windows service convention for $packageId..."
		
		$service = Get-WmiObject win32_service -Filter "name='$packageId'"
		if ($service -eq $null) {
			$service = Get-WmiObject win32_service -Filter "name='$packageId-$environmentName'"
		}

		if ($service -eq $null) {
			Write-Host "No service was found for the package. The convention will not be used."	
		}
		else {
			$oldPath = $service.PathName
			$isValid = $oldPath -match '^"?([^"]+)"?'
			if ($isValid) {
				$executablePath = $matches[1]

				$serviceName = $service.Name

				Write-Host "Windows service '$serviceName' currently running from $executablePath."

				$processExecutable = Split-Path $executablePath -Leaf
				$newExecutablePath = Join-Path (Join-Path $sourcePath content) $processExecutable 
				$newPath = $oldPath -replace [RegEx]::Escape($executablePath),$newExecutablePath

				Write-Host "Windows service '$serviceName' is being reconfigured to run from $newExecutablePath..."
				"The old command line for the service was: "
				"$oldPath"
				"The new command line for the service is: "
				"$newPath"
				$result = $service.Change($null, $newPath, $null, $null, $null, $null, $null, $null, $null, $null, $null)
				Restart-Service $service.Name
			}
			else {
				"The path name format $oldPath is not supported."
			}
		}
	}
}

