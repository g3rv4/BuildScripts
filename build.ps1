$basePath = Join-Path (Get-Location) .build
$publishPath = Join-Path $basePath publish
$manifestPath = Join-Path $publishPath BuildScripts.psd1
$packagesPath = Join-Path $basePath packages
$nuspecPath = Join-Path $publishPath BuildScripts.nuspec

if (Test-Path $basePath) {
  Remove-Item $basePath -Recurse -Force
}

New-Item -Path $basePath -ItemType 'Container' | Out-Null
New-Item -Path $packagesPath -ItemType 'Container' | Out-Null

dotnet tool restore
$version = (dotnet tool run nbgv get-version -f json | ConvertFrom-Json).SimpleVersion
Write-Host "Version is $version"

Copy-Item BuildScripts $publishPath -Recurse
(Get-Content BuildScripts.nuspec).Replace('$version$', $version) | Set-Content $nuspecPath
(Get-Content $manifestPath).Replace("ModuleVersion = '0.0.1'", "ModuleVersion = '$version'") | Set-Content $manifestPath

$nupkgPath = Join-Path $packagesPath "BuildScripts.$($version).nupkg"
Compress-Archive -Path "$($publishPath)/*" -DestinationPath $nupkgPath
