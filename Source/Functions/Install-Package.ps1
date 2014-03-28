# .ExternalHelp  powerdeploy.psm1-help.xml
function Install-Package {
[CmdletBinding()] 
param (
	[string][parameter(Position = 0, Mandatory = $true)]$PackageArchive,
	[string][parameter(Position = 1, Mandatory = $true)]$Environment,
	[parameter(Mandatory = $true)]
	[string]$DeploymentTempRoot,
	[string]$Role,
	[string]$PackageTargetPath
)
	Write-Host ('='*80)
	Write-Host ("powerdeploy $global:PDVersion on $env:computername")
	Write-Host ('='*80)

	$ErrorActionPreference = 'Stop'

	Write-Host "Installing package $PackageArchive for the $Environment environment..."

	$packageFileName = Split-Path $PackageArchive -Leaf
	$packageNameWithVersion = [System.IO.Path]::GetFileNameWithoutExtension($packageFileName)

	if ($PackageTargetPath -ne $null -and $PackageTargetPath.Length -gt 0) {
		$requestedExtractionPath = $PackageTargetPath
	}
	else {
		$packagesRoot = $env:packagedeployroot
		if ($packagesRoot -eq $null) { $packagesRoot = "$($env:temp)\deploy.packages" }
		$requestedExtractionPath = ("$packagesRoot\$Environment\$packageNameWithVersion" -replace 'PD_', '')
	}
	
	$extractionPath = GenerateExtractionPath $requestedExtractionPath

	# Unzip the package
	ExtractPackage $PackageArchive $extractionPath

	if ($packageNameWithVersion -match '^(PD_)?(?<Package>[^_]+)_(?<Version>.+)$' -eq $false) {
		Throw "Not a valid package name."
	}
	$packageId = $matches.Package
	$packageVersion = $matches.Version
	
	Write-Host "Installing version $packageVersion of package $packageId..."

	ExecuteInstallation `
		-PackageName $packageId `
		-PackageVersion $packageVersion `
		-EnvironmentName $Environment `
		-DeployedFolderPath $extractionPath `
		-DeploymentSourcePath $DeploymentTempRoot
	
	Write-Verbose 'Package installation completed without errors.'
}

