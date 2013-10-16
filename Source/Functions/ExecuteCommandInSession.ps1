function ExecuteCommandInSession {
    param (
        [ScriptBlock]$ScriptBlock
    )
    Invoke-Command -Session $Script:CurrentPowerDeployCommandSession -ScriptBlock $ScriptBlock
}

function SetCurrentPowerDeployCommandSession {
    param (
        $Session
    )

    $Script:CurrentPowerDeployCommandSession = $Session
}