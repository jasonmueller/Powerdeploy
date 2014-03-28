function ExtractPackage {
    param (
        [Parameter(Mandatory = $true)]
        $PackagePath,
        [Parameter(Mandatory = $true)]
        $TargetPath
    )

    Write-Verbose "Extracting $PackagePath to $TargetPath..."
    $packageTarget = New-Item $TargetPath -ItemType Directory -Force    
    ExpandZipArchive $PackagePath $TargetPath
    Write-Verbose "Package successfully extracted."
}