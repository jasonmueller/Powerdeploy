function New-DeploymentPackage {
    param (
        [String]
        [Parameter(Position = 0, Mandatory = $true)]
        $SourcePath,

        [String]
        [Parameter(Position = 1, Mandatory = $true)]
        $PackageName,

        [String]
        [Parameter(Position = 2, Mandatory = $true)]
        $Version,

        [String]
        [Parameter(Mandatory = $true)]
        $OutputDirectoryPath
    )

    function CreateZipArchive {
        param (
            $Source,
            $Destination
        )   

        $archivePath = $Destination
        $7zip = Resolve-Path $PSScriptRoot\..\Tools\7za.exe

        $arguments = "a -r -y `"$archivePath`" `"$source`""
        Write-Host $arguments
        $process = [Diagnostics.Process]::Start($7zip, $arguments)
        $process.WaitForExit()
    }

    $archivePath = [System.IO.Path]::Combine((Resolve-Path $OutputDirectoryPath), "PD_$($PackageName)_$($Version).zip")

    if (Test-Path $archivePath) {
        Remove-Item $archivePath
    }

    CreateZipArchive (Join-Path (Resolve-Path $SourcePath) '*') $archivePath

    Get-Item $archivePath
}
