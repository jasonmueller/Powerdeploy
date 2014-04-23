# Run custom deployment scripts
@{
	metadata = @{
		conventionName = "Custom Deployment Scripts"
		supportsContext = $true
	}
	
	onDeploy = {
		param (
			$PowerDeploymentContext
		)

		$scripts = Get-ChildItem $PowerDeploymentContext.Parameters.ExtractedPackagePath Deploy.ps1 -Recurse
		if ($scripts -ne $null) {
			foreach ($script in $scripts){
				Write-Host "Executing deployment script $($script.FullName)..."
				&$script.FullName
			}
		}
		else {
			'No custom deployment scripts were found to execute.'
		}
	}
}