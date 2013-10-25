properties {
  $buildFolder = Join-Path $PSScriptRoot '_build'
  $sourceFolder = Join-Path $PSScriptRoot 'Source'
  $version = git describe --tags --always --dirty
  $changeset = 'n/a'
}

task default -depends Build
task Build -depends Clean, Test, Package
task Package -depends Version, Squirt, Unversion

task Squirt {
    Copy-Item $sourceFolder\* $buildFolder -Recurse -Exclude .git
    Get-ChildItem $buildFolder *.Tests.ps1 -Recurse | Remove-Item
}

task Test { 
    exec {."$PSScriptRoot\pester\bin\pester.bat" "$sourceFolder"}
}

task Version {
    #$v = git describe --abbrev=0 --tags
    #$changeset=(git log -1 $($v + '..') --pretty=format:%H)
    if ($changeset -eq $null -or $changeset -eq '') {
        throw 'No changeset.  Files have been modified since commit.'
    }
    (Get-Content "$sourceFolder\PowerDeploy.psm1") `
        | % {$_ -replace "\`$version\`$", "$version" } `
        | % {$_ -replace "\`$sha\`$", "$changeset" } `
        | Set-Content "$sourceFolder\PowerDeploy.psm1"
}

task Unversion {
    #$v = git describe --abbrev=0 --tags
    #$changeset=(git log -1 $($v + '..') --pretty=format:%H)
    (Get-Content "$sourceFolder\PowerDeploy.psm1") `
      | % {$_ -replace "$version", "`$version`$" } `
      | % {$_ -replace "$changeset", "`$sha`$" } `
      | Set-Content "$sourceFolder\PowerDeploy.psm1"
}

task Clean { 
    if (Test-Path $buildFolder) {
        Remove-Item $buildFolder -Recurse -Force
    }
    New-Item $buildFolder -ItemType Directory | Out-Null
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}