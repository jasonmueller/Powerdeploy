function Publish-Package {
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
	$deploymentId = [Guid]::NewGuid().ToString("N")

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
    $remoteCommand = "`$ErrorActionPreference = 'Stop';"
	$remoteCommand += "Import-Module $localPackageTempDir\scripts\PowerDeploy.psm1;"
	$remoteCommand += "Install-Package $localPackageTempDir\package\$packageFileName $Environment"
	$remoteCommand += " -DeploymentTempRoot $localPackageTempDir"
	if (![String]::IsNullOrEmpty($Role)) { $remoteCommand += " -Role $Role" }
	if ($RemotePackageTargetPath -ne $null -and $RemotePackageTargetPath.Length -gt 1) { $remoteCommand += " -PackageTargetPath $RemotePackageTargetPath" }
	$remoteCommand += " -PostInstallScript { $PostInstallScript }"
	$remoteCommand += " -Verbose:`$$($PSBoundParameters['Verbose'] -eq $true)"
	
	Write-Host "Executing command $remoteCommand on target $ComputerName..."
	$parameters = @{
		ScriptBlock = (Invoke-Expression " { $remoteCommand } ")
		Session = $remoteSession
	}
	
	Write-Host ('-'*80)
	Write-Host "  Beginning remote execution on $ComputerName..." 
	Write-Host ('-'*80)
	
	Write-Host "Executing installation..."
	ExecuteCommandInSession (Invoke-Expression " { $remoteCommand } ")

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

