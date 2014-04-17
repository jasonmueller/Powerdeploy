function Invoke-Powerdeploy {
	# .ExternalHelp ..\powerdeploy.psm1-help.xml
	[CmdletBinding()]
	param (
		[string][parameter(Position = 0, Mandatory = $true)]$PackageArchive,
		[string][parameter(Position = 1, Mandatory = $true)]$Environment,
		[string]$Role,
		[string]$ComputerName = "localhost",
		[System.Management.Automation.PSCredential]$Credential,
		[string]$RemotePackageTargetPath,
		[System.Uri]$SettingsUri,
		[scriptblock]$PostInstallScript = { }	
	)
	Write-Host ('='*80)
	Write-Host "powerdeploy $global:PDVersion"
	Write-Host ('='*80)

	$ErrorActionPreference = 'Stop'
	$deploymentId = GenerateUniqueDeploymentId

	if (!(Test-Path $PackageArchive)) {
		throw "The package specified does not exist: $PackageArchive"
	}

	Write-Host "Beginning deployment of package '$(Split-Path $PackageArchive -Leaf)' for environment '$Environment' to $ComputerName..."
	
	$remoteSession = CreateRemoteSession -ComputerName $ComputerName -Credential $Credential
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

	DeployFilesToTarget "$remotePackageTempDir" "$PSScriptRoot\.." $PackageArchive -Settings $settings -Credential $Credential

	# Execute deployment script on remote.
	$packageFileName = Split-Path $PackageArchive -Leaf
	# if (![String]::IsNullOrEmpty($Role)) { $remoteCommand += " -Role $Role" }

	# Build up the Install-Package parameters and convert it to a string
	# that we can send to the target for splatting.  If we don't convert
	# it to a string, we'll just end up passing the type name (Hashtable)
	# to the target.
	$installParameters = @{
		PackageArchive = "$localPackageTempDir\package\$packageFileName"
		Environment = $Environment
		DeploymentTempRoot =  $localPackageTempDir
		PostInstallScript = $PostInstallScript
		PackageTargetPath = $RemotePackageTargetPath
		Settings = $settings
		Verbose = $PSBoundParameters['Verbose'] -eq $true
	} | ConvertTo-StringData | Out-String
	# if ($RemotePackageTargetPath -ne $null -and $RemotePackageTargetPath.Length -gt 1) { $remoteCommand += " -PackageTargetPath $RemotePackageTargetPath" }

	# Build up the sequence of commands to execute on the target.
	$remoteCommands = @(
		# We will immediately fail remote execution on an error.
		"`$ErrorActionPreference = 'Stop'",

		# Import Powerdeploy on the target so we can access our Install-Package Cmdlet.
		"Import-Module '$localPackageTempDir\scripts\Powerdeploy.psm1'",

		# Send our installation parameters variable across and then install the package
		# splatting in the installation parameters.
		"`$installParameters = $installParameters; Install-Package @installParameters"
	)

	Write-Host ('-'*80)
	Write-Host "  Beginning remote execution on $ComputerName..." 
	Write-Host ('-'*80)
	
	Write-Host "Executing installation on target..."
	$remoteCommands | ForEach-Object { ExecuteCommandInSession (Invoke-Expression "{ $_ }") }

	Write-Host ('-'*80)
	Write-Host "  Remote execution complete."
	Write-Host ('-'*80) 

	if ($remoteSession -ne $null) {
		Write-Verbose "Closing remote session..."
		Remove-PSSession $remoteSession
	}

	# Clean up the package.
	Write-Verbose "Removing the package from the temporary deployment location..."
	try {
		Remove-Item $remotePackageTempDir -Recurse -Force
	}
	catch {
		# Don't fail the deployment if we can't clean up files.
	}
}

function GenerateUniqueDeploymentId() {
	[Guid]::NewGuid().ToString("N")
}