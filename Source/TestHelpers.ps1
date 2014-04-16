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

function Get-CalledMock {
    param(
        [string]$CommandName
    ) 

    $global:mockCallHistory | ? CommandName -eq $CommandName | % { 
        $mock = $_
        Write-Host $_.CommandName "was called with " 
        ($mock.BoundParams).GetEnumerator() | Write-Host
    }
}