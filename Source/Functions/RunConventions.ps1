function RunConventions {
    param (
        [Parameter(Mandatory = $true)]
        $conventionFiles,
        [Parameter(Mandatory = $true)]
        $deploymentContext
    )

    Write-Host "`r`nExecuting deployment conventions..."
    $conventionFiles | ForEach-Object {
        $convention = (& $_)
        $metadata = $convention.metadata
        Write-Host "`r`nExecuting convention [$($metadata.conventionName)]..."

        $onDeploy = $convention.onDeploy
        &$onDeploy -PowerDeploymentContext $deploymentContext
    } 
}
 
