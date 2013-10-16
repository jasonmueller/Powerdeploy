function GenerateExtractionPath {
    param (
        [Parameter(Mandatory = $true)]
        $initialPath
    )

    $finalPath = $null

    if (Test-Path $initialPath) {
        Write-Verbose "The extraction path requested '$initialPath' already exists.  A unique path will be generated."
        foreach ($i in 1..99) {
            $incrementedPath = "$($initialPath)__{0:D2}" -f $i
            if (!(Test-Path $incrementedPath)) {
                $finalPath = $incrementedPath
                break
            }
        }

        if ($finalPath -eq $null) {
            throw 'A directory name could not be generated because all names up to __99 were allocated.'
        }
    }
    else {
        $finalPath = $initialPath
    }

    $finalPath
}