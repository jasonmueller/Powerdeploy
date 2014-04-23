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

        New-Object PSObject -Property @{
            BoundParameters = $mock.BoundParams
        }
    }
}