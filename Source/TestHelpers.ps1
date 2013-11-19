function Capture ([ScriptBlock] $script) {
    $exception = $null

    try { 
        & $script | Out-Null
    }
    catch [System.Exception] {
        $exception = $_.Exception
    }

    $exception
}
