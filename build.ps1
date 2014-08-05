properties {
  $buildFolder = Join-Path $PSScriptRoot '_build'
  $packageFolder = Join-Path $PSScriptRoot '_package'
  $sourceFolder = Join-Path $PSScriptRoot 'Source'
  $acceptanceTestFolder = Join-Path $PSScriptRoot 'AcceptanceTests'
  $version = git describe --tags --always --dirty
  $changeset = 'n/a'
}

task default -depends Build
task Build -depends Clean, Test, Package
task Package -depends Version, Squirt, Unversion, Zip, AcceptanceTest

task Zip {
    Copy-Item $buildFolder $packageFolder\temp\Powerdeploy -Recurse
    $version -match '^v?(?<version>.+)$'
    $strippedVersion = $matches.version
    exec { ."$sourceFolder\Tools\7za.exe" a -r "$packageFolder\Powerdeploy-$strippedVersion.zip" "$packageFolder\temp\Powerdeploy" }
}

task Squirt {
    Copy-Item $sourceFolder\* $buildFolder -Recurse -Exclude .git
    Get-ChildItem $buildFolder *.Tests.ps1 -Recurse | Remove-Item
    Get-ChildItem $buildFolder TestHelpers.ps1 | Remove-Item
    Get-ChildItem $buildFolder Test.xml | Remove-Item

    $version -match 'v(?<versionnum>[0-9]+\.[0-9]+(.[0-9]+)?)'
    New-ModuleManifest `
      -Author 'Jason Mueller' `
      -CompanyName 'Suspended Gravity, LLC' `
      -Path $buildFolder\Powerdeploy.psd1 `
      -ModuleVersion $matches.versionnum `
      -Guid 'cb196f97-00e0-416c-b201-a7b887b6d257' `
      -RootModule Powerdeploy.psm1
}

task Test { 
    exec {."$PSScriptRoot\pester\bin\pester.bat" "$sourceFolder"}
}

task AcceptanceTest {
    exec {."$PSScriptRoot\pester\bin\pester.bat" "$acceptanceTestFolder"}
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
    if (Test-Path $packageFolder) {
        Remove-Item $packageFolder -Recurse -Force
    }
    New-Item $buildFolder -ItemType Directory | Out-Null
}

task ? -Description "Helper to display task info" {
    Write-Documentation
}