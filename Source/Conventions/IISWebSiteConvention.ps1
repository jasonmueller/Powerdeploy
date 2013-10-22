# If there is a website matching the package name, update the site
# physical path to the content dir.
@{
	metadata = @{
		conventionName = "IIS Website convention"
	}
	
	onDeploy = {
		param (
			[Parameter(Mandatory = $true)]
			$PowerDeploymentContext
		)
		
		$packageId = $PowerDeploymentContext.Parameters.PackageId
		$sourcePath = $PowerDeploymentContext.Parameters.ExtractedPackagePath
		$environmentName = $PowerDeploymentContext.Parameters.EnvironmentName

		$iisRegistryKeyPath = 'HKLM:\software\microsoft\InetStp'
		
		if (!(Test-Path $iisRegistryKeyPath)) {
			Write-Host ('IIS installation was not found. '`
            + 'The convention will be skipped.')
            return
		}

		$siteFound = $false

		$iisVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp"
		if ($iisVersion.MajorVersion -eq 6) {
			$validSiteNames = @(
				"$packageId",
				"$packageId-$environmentName"
			)

			# IIS 6 requires that we use ADSI.
			# Find the first web site that matches one of our valid names.
			$webserver = [ADSI]"IIS://localhost/w3svc"
			$site = $webserver.children | Where-Object {
				$_.schemaClassName -eq "IIsWebServer" -and $validSiteNames -contains $_.ServerComment
			} | Select-Object -First 1

			if ($site -ne $null) {
				$siteFound = $true

				# We need to get the root virtual directory for the site in order to get
				# the path to the home directory.
				$root = $site.children | Where-Object { $_.name -eq 'root' }
				$root.Path = "$sourcePath\content"
				$root.SetInfo()
			}
		}
		else {
			# IIS 7 or greater can use web administration.
			$validSiteNames = @(
				"IIS:\Sites\$packageId",
				"IIS:\Sites\$packageId-$environmentName"
			)
			
			Load-WebAdministration

			$validSiteNames | ForEach-Object {
				Write-Verbose "Looking for site $_..."
				if (Test-Path $_) {
					Write-Host "A site was found that matched the package. The physical path for '$_' will be redirected to the new content."
					Set-ItemProperty $_ -Name physicalPath -Value "$sourcePath\content"
					$siteFound = $true
				}
			}
			
			Unload-WebAdministration	
		}
			
		if ($siteFound -eq $false) {
			Write-Host "No site was found for the package. The convention will not be used."
		}
	}
}

