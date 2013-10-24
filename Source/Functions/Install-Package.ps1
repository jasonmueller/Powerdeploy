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
	Write-Host ('powerdeploy $version$' + "on $env:computername")
	Write-Host ('='*80)

	$ErrorActionPreference = 'Stop'
	
	Import-Pscx

	"Installing package $PackageArchive for the $Environment environment..."

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
	
	$context = BuildDeploymentContext $packageId $packageVersion $DeploymentTempRoot $Environment $extractionPath

	"Installing version $packageVersion of package $packageId..."

	RunConventions (Resolve-Path $PSScriptRoot\Conventions\*Convention.ps1) $context

	# Run PostDeploy
	Remove-Module pscx -Verbose:$false
}

