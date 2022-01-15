$basePath = Join-Path (Get-Location) .build
$publishPath = Join-Path $basePath publish
$packagesPath = Join-Path $basePath packages

if (Test-Path $basePath) {
  Remove-Item $basePath -Recurse -Force
}

New-Item -Path $basePath -ItemType 'Container' | Out-Null
New-Item -Path $packagesPath -ItemType 'Container' | Out-Null

dotnet tool restore
$version = (dotnet tool run nbgv get-version -f json | ConvertFrom-Json).SimpleVersion

Copy-Item ./BuildScripts $publishPath
$nuspecPath = Join-Path $publishPath buildscripts.nuspec
(Get-Content buildscripts.nuspec).Replace('$version$', $version) | Set-Content $nuspecPath

$nupkgPath = Join-Path $packagesPath "buildscripts.$($version).nupkg"
Compress-Archive -Path "$($publishPath)/*" -DestinationPath $nupkgPath
