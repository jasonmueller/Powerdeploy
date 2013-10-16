function GetPackageTempDirectoryOnTarget {
	param(
	)

    $tempDir = ExecuteCommandInSession { $env:PowerDeployPackageTemp }
    if ($tempDir -eq $null) {
        $tempDir = 'c:\pdpackages.tmp'
        Write-Verbose "No PowerDeployPackageTemp environment variable was found.  Using '$tempDir'."
    }
    else {
        Write-Verbose "Specified temporary package directory '$tempDir' will be used."
    }

    return @{
        Share = $tempDir -replace '(\w)(?::)',"`$1$"
        LocalPath = $tempDir
    }
}

function GetPackageTempDirectoryAndShareOnTarget {
    param()

    $packageShare = ExecuteCommandInSession { $env:PowerDeployPackageShare }
    if ($packageShare -eq $null) {
        Write-Verbose "No PowerDeployPackageShare environment variable was found."
        return GetPackageTempDirectoryOnTarget
    }
    else {
        Write-Verbose "The package share specified by PowerDeployPackageShare environment variable is '$packageShare'."
    }

    # We need to expand the variable on our end because it won't exist on the target computer if
    # we simply pass it across as part of the remote command.
    $shareLocalPath = ExecuteCommandInSession (Invoke-Expression " { (Get-WmiObject Win32_Share -Filter ""Name = '$packageShare'"").Path } ")
    Write-Verbose "The local path for the PowerDeploymentPackageShare on the target is $shareLocalPath."

    return @{
        Share = "$packageShare\pdpackage.tmp"
        LocalPath = "$shareLocalPath\pdpackage.tmp"
    }
}