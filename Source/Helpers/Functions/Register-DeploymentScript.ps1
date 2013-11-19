$global:pddeploymentscripts = @{
    'pre-Install' = @()
    'post-Install' = @()
}

function Register-DeploymentScript {
    [CmdletBinding()]
    param (
        [ScriptBlock]
        [Parameter(Mandatory = $true)]
        $Script,

        [Switch]
        [Parameter(ParameterSetName = "Pre", Mandatory = $true)]
        $Pre,

        [Switch]
        [Parameter(ParameterSetName = "Post", Mandatory = $true)]
        $Post,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Install")]
        $Phase
    )

    $prePost = "post"
    if ($Pre) {
        $prePost = "pre"
    }

    $($global:pddeploymentscripts)."$prePost-$Phase" = $Script
}

function Get-RegisteredDeploymentScript {
    [CmdletBinding()]
    param (
        [Switch]
        [Parameter(ParameterSetName = "Pre", Mandatory = $true)]
        $Pre,

        [Switch]
        [Parameter(ParameterSetName = "Post", Mandatory = $true)]
        $Post,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Install")]
        $Phase
    )

    $prePost = "post"
    if ($Pre) {
        $prePost = "pre"
    }

    @( $($global:pddeploymentscripts)."$prePost-$Phase" )
}

function Invoke-RegisteredDeploymentScript {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        $Script
    )

    process {
        & $Script
    }
}