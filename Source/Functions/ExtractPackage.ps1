function ExtractPackage {
    param (
        [Parameter(Mandatory = $true)]
        $PackagePath,
        [Parameter(Mandatory = $true)]
        $TargetPath
    )

    Write-Verbose "Extracting package to $TargetPath..."
    $packageTarget = New-Item $TargetPath -ItemType Directory -Force    
    Expand-Archive $PackagePath $TargetPath
    Write-Verbose "Package successfully extracted."
}