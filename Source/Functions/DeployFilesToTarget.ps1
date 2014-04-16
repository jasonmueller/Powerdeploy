function DeployFilesToTarget {
    param (
        $DeploymentTempRoot,
        $ScriptRoot,
        $PackagePath,
        $Settings,
        $Credential = $null
    )
    
    $deployTempDriveRoot = [System.IO.Path]::GetPathRoot($DeploymentTempRoot)
    $driveParams = @{
        Name = 'DeploymentRoot'
        PSProvider = 'FileSystem'
        Root = $deployTempDriveRoot
    }
    if ($Credential -ne $null) {
        $driveParams.Credential = $Credential
    }

    Write-Verbose "Connecting DeploymentRoot: drive to $deployTempDriveRoot..."
    New-PSDrive @driveParams | Out-Null

    $packageTempRoot = "$DeploymentTempRoot\package"
    $scriptTempRoot = "$DeploymentTempRoot\scripts"
    $settingsTempRoot = "$DeploymentTempRoot\settings"

    Write-Verbose "Deploying files to target '$DeploymentTempRoot'..."

    try {
       New-Item -Path $DeploymentTempRoot -ItemType Directory | Out-Null
    }
    catch [Exception] {
        Write-Error ("The deployment directory could not be created at $DeploymentTempRoot. " +
            "Ensure that the current user has access to both the package share and the target filesystem " +
            "represented by the share.  Alternatively, set a PowerDeployPackageShare environment variable " +
            "on the target system that the current user has access to.")
        throw $_
    }

    Write-Verbose 'Deploying deployment scripts to target...'
    Copy-Item $ScriptRoot $scriptTempRoot -Recurse
    
    Write-Verbose 'Deploying package to target...'
    New-Item -Path $packageTempRoot -ItemType Directory | Out-Null
    Copy-Item $PackagePath $packageTempRoot\

    if ($Settings -ne $null) {
        Write-Verbose 'Deploying settings to target computer for integration at install...'
        New-Item -Path $settingsTempRoot -ItemType Directory | Out-Null
        $Settings | ConvertTo-StringData | Out-File $settingsTempRoot\Settings.pson
    }
    else {
        Write-Verbose 'No settings uri was specified, so none will be deployed.'
    }
}

function ConvertTo-StringData
{ 
    Begin 
    { 
        $level = 0
        function Expand-Value
        {
            param($value)

            if ($value -ne $null) {
                switch ($value.GetType().Name)
                {
                    'String' { "'$value'" }
                    'Boolean' { "`$$value" }
                    'Hashtable' { Write-Hashtable $value }
                    'ScriptBlock' { "{ $value }"}
                    default { $value }
                }
            }
            else
            { "`$null" }

        }

        function Write-ValuePair {
            param ($name, $value)

            Get-IndentedString "'$name' = $(Expand-Value $value)`n"
        }

        function Write-Hashtable {
            param ($hashtable)

            $serialized = "@{`n"
            $level++
            $serialized += $hashtable.GetEnumerator() | ForEach-Object { Write-ValuePair $_.Name $_.Value }
            $level--
            $serialized += Get-IndentedString "}"

            Write-Output $serialized
        }

        function Get-IndentedString {
            param ($output)

            $indent = ' ' * ($level * 4)
            "$indent$($output.ToString())"
        }
    } 
    Process 
    { 
        $string += Write-Hashtable $_
    } 
    End 
    { 
        Write-Output $string
    }
} 
