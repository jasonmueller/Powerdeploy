# powerdeploy
# Version: $version$
# Changeset: $sha$
#
# Copyright (c) 2011 Jason Mueller
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#Requires -Version 2.0

Resolve-Path $PSScriptRoot\Functions\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

# .ExternalHelp  powerdeploy.psm1-help.xml
function Publish-Package {
[CmdletBinding()]
param (
	[string][parameter(Position = 0, Mandatory = $true)]$PackageArchive,
	[string][parameter(Position = 1, Mandatory = $true)]$Environment,
	[string]$Role,
	[string]$ComputerName,
	[System.Management.Automation.PSCredential]$RemoteCredential,
	[string]$RemotePackageTargetPath,
	[System.Uri]$SettingsUri
)
	Write-Host ('='*80)
	Write-Host 'powerdeploy $version$'
	Write-Host ('='*80)

	$ErrorActionPreference = 'Stop'
	$deploymentId = [Guid]::NewGuid().ToString("N")

	"Beginning deployment of package '$(Split-Path $PackageArchive -Leaf)' for environment '$Environment' to $ComputerName..."
	
	$remoteSession = CreateRemoteSession -ComputerName $ComputerName -Credential $RemoteCredential
	SetCurrentPowerDeployCommandSession $remoteSession

	$packagePaths = GetPackageTempDirectoryAndShareOnTarget
	$remoteTempRoot = "\\$ComputerName\$($packagePaths.Share)"
	$localTempRoot = $packagePaths.LocalPath

	$localPackageTempDir = [System.IO.Path]::Combine($localTempRoot, $deploymentId)
	$remotePackageTempDir = Join-Path $remoteTempRoot $deploymentId
		
	if ($SettingsUri -ne $null) {
    	$settings = GetSettingsFromUri $SettingsUri $Environment $ComputerName $Role
	}
	else {
		$settings = @{}
	}

	# Explicitly set the execution policy on the target so we don't need to depend
	# on it being set for us.
	ExecuteCommandInSession { Set-ExecutionPolicy RemoteSigned -Scope Process }

	DeployFilesToTarget $remotePackageTempDir $PSScriptRoot $PackageArchive -Settings $settings

	# Execute deployment script on remote.
	$packageFileName = Split-Path $PackageArchive -Leaf
	$remoteCommand = "Import-Module $localPackageTempDir\scripts\PowerDeploy.psm1;"
	$remoteCommand += "Install-Package $localPackageTempDir\package\$packageFileName $Environment"
	$remoteCommand += " -DeploymentTempRoot $localPackageTempDir"
	if (![String]::IsNullOrEmpty($Role)) { $remoteCommand += " -Role $Role" }
	if ($RemotePackageTargetPath -ne $null -and $RemotePackageTargetPath.Length -gt 1) { $remoteCommand += " -PackageTargetPath $RemotePackageTargetPath" }
	$remoteCommand += " -Verbose:`$$($PSBoundParameters['Verbose'] -eq $true)"
	
	"Executing command $remoteCommand on target $ComputerName..."
	$parameters = @{
		ScriptBlock = (Invoke-Expression " { $remoteCommand } ")
		Session = $remoteSession
	}
	
	('-'*80)
	"  Beginning remote execution on $ComputerName..." 
	('-'*80)
	
	Invoke-Command @parameters

	('-'*80)
	"  Remote execution complete."
	('-'*80) 

	Write-Verbose "Closing remote session..."
	Remove-PSSession $remoteSession

	# Clean up the package.
	"Removing the package from the temporary deployment location..."
	try {
		Remove-Item $remotePackageTempDir -Recurse -Force
	}
	catch {
		# Don't fail the deployment if we can't clean up files.
	}
}

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

function Load-WebAdministration {
	$iisVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp";
	if ($iisVersion.MajorVersion -eq 7)
	{
		if ($iisVersion.MinorVersion -ge 5)
		{
			Import-Module WebAdministration -Verbose:$false
		}           
		else
		{
			if (-not (Get-PSSnapIn | Where {$_.Name -eq "WebAdministration";})) {
				Add-PSSnapIn WebAdministration;
			}
		}
	}
}

function Unload-WebAdministration {
	$iisVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp";
	if ($iisVersion.MajorVersion -eq 7)
	{
		if ($iisVersion.MinorVersion -ge 5)
		{
			Remove-Module WebAdministration;
		}           
		else
		{
			if (-not (Get-PSSnapIn | Where {$_.Name -eq "WebAdministration";})) {
				Remove-PSSnapIn WebAdministration;
			}
		}
	}
}

function Import-Pscx {
	if ($PSVersionTable.PSVersion.Major -ge 3) {
		"PowerShell v3 or higher detected.  Using PowerShell Community Extension version 3."
		Import-Module $PSScriptRoot\Modules\pscx.v3\pscx -Verbose:$false
	}
	else {
		"PowerShell v3 not detected.  Using PowerShell Community Extension version 2."
		Import-Module $PSScriptRoot\Modules\pscx\pscx -Verbose:$false
	}
}

Export-ModuleMember Install-Package, Publish-Package, Load-WebAdministration, Unload-WebAdministration
