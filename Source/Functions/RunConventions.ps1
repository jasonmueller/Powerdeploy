function RunConventions {
    param (
        [Parameter(Mandatory = $true)]
        $conventionFiles,
        [Parameter(Mandatory = $true)]
        $deploymentContext
    )

    Write-Verbose "`r`nExecuting deployment conventions..."
    $conventionFiles | ForEach-Object {
        $convention = (& $_)
        $metadata = $convention.metadata
        Write-Verbose "`r`nExecuting convention [$($metadata.conventionName)]..."

        $onDeploy = $convention.onDeploy
        &$onDeploy -PowerDeploymentContext $deploymentContext
    } 
}
 
