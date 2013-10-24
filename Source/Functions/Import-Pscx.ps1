function Import-Pscx {
    if ($PSVersionTable.PSVersion.Major -ge 3) {
        "PowerShell v3 detected.  Using PowerShell Community Extension version 3."
        Import-Module $PSScriptRoot\..\Modules\pscx.v3\pscx -Verbose:$false
    }
    else {
        "PowerShell v3 not detected.  Using PowerShell Community Extension version 2."
        Import-Module $PSScriptRoot\..\Modules\pscx\pscx -Verbose:$false
    }
}

