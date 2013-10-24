function ExecuteInstallation (
    $PackageName, 
    $PackageVersion, 
    $EnvironmentName, 
    $DeployedFolderPath) { 

    Import-Module "$PSScriptRoot\..\Helpers\Installer.psm1"
    
    # Set up the context to transition to the module.
    # It may seem odd here that we are importing a module and setting up a context
    # to run conventions in, rather than just using include functions like we do
    # for all of the steps that lead up to here, but ExecuteInstallation is really
    # the transition point between the "internal" side of Powerdeploy, and the
    # "consumable" side that is exposed to conventions and deployment packages.
    # For this reason, we don't want them to rely on "internals", but rather on
    # the installation module with it's published commandlets, etc.
    Set-DeploymentContext `
        -EnvironmentName $EnvironmentName `
        -DeployedFolderPath $DeployedFolderPath `
        -PackageName $PackageName `
        -PackageVersion $PackageVersion

    $context = BuildDeploymentContext $PackageName $PackageVersion 'deprecated' $EnvironmentName $DeployedFolderPath

    Set-DeploymentContext -Variables $context.Settings
    
    RunConventions (Resolve-Path $PSScriptRoot\..\Conventions\*Convention.ps1) $context

    Write-Host 'Installation finished.'

    Write-Verbose 'Unloading installation module...'
    Remove-Module Installer -Verbose:$false -ErrorAction SilentlyContinue
}
