function ExecuteInstallation (
    $PackageName, 
    $PackageVersion, 
    $EnvironmentName, 
    $DeployedFolderPath,
    $DeploymentSourcePath) { 

    Import-Module "$PSScriptRoot\..\Helpers\Installer.psm1"

    # Set up the context to transition to the module.
    # It may seem odd here that we are importing a module and setting up a context
    # to run conventions in, rather than just using include functions like we do
    # for all of the steps that lead up to here, but ExecuteInstallation is really
    # the transition point between the "internal" side of Powerdeploy, and the
    # "consumable" side that is exposed to conventions and deployment packages.
    # For this reason, we don't want them to rely on "internals", but rather on
    # the installation module with it's published commandlets, etc.
    $context = BuildDeploymentContext `
        $PackageName `
        $PackageVersion `
        $DeploymentSourcePath `
        $EnvironmentName `
        $DeployedFolderPath

    $newStyleContext = @{
        PackageName = $PackageName
        PackageVersion = $PackageVersion
        DeployedFolderPath = $DeployedFolderPath
        EnvironmentName = $EnvironmentName
        Variables = $context.Settings
    }

    Set-DeploymentContext @newStyleContext #-Variables $context.Settings
    
    $initializationScriptPath = "$DeployedFolderPath\deploy\Initialize.ps1"
    Write-Host $initializationScriptPath
    if (Test-Path $initializationScriptPath) {
        Write-Verbose "An initialization script was found for the package and is being run..."
        & $initializationScriptPath
    }

    Get-RegisteredDeploymentScript -Pre -Phase Install | Invoke-RegisteredDeploymentScript

    RunConventions (Resolve-Path $PSScriptRoot\..\Conventions\*Convention.ps1) $context

    Write-Host 'Installation finished.'

    Write-Verbose 'Unloading installation module...'
    Remove-Module Installer -Verbose:$false -ErrorAction SilentlyContinue
}
