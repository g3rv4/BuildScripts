function Build-DotNetPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $ProjectName,

        [Parameter(Mandatory = $true)]
        [string] $DockerImage
    )
    process {
        $basePath = Get-Location
        $buildPath = Join-Path (Get-Location) .build
        $publishPath = Join-Path $buildPath publish
        $packagesPath = Join-Path $buildPath packages
        $nuspecPath = Join-Path $publishPath BuildScripts.nuspec

        if (Test-Path $buildPath) {
            Remove-Item $buildPath -Recurse -Force
        }
        
        New-Item -Path $buildPath -ItemType 'Container' | Out-Null
        New-Item -Path $packagesPath -ItemType 'Container' | Out-Null
        
        $uid = sh -c 'id -u'
        $gid = sh -c 'id -g'
        
        docker run --rm -v "$($basePath):/var/src" -v "$($publishPath):/var/publish" $DockerImage ash -c "dotnet publish -c Release /var/src/$ProjectName/$ProjectName.csproj -o /var/publish && chown -R $($uid):$($gid) /var/publish"
        
        $version = [version](Get-Item "$publishPath/$ProjectName.dll").VersionInfo.FileVersion
        $version = "$($version.Major).$($version.Minor).$($version.Build)"
        
        Write-Output "Version is $version"
        
        $nuspecPath = Join-Path $publishPath "$ProjectName.nuspec"
        (Get-Content "$ProjectName.nuspec").Replace('$version$', $version) | Set-Content $nuspecPath
        
        $nupkgPath = Join-Path $packagesPath "$ProjectName.$($version).nupkg"
        Compress-Archive -Path "$($publishPath)/*" -DestinationPath $nupkgPath
        
        if ($env:GITHUB_ENV) {
            Write-Output "VERSION=$version" | Out-File -FilePath $env:GITHUB_ENV -Encoding utf8 -Append
        }
    }
}
