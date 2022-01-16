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
        $publishPath = Join-Path $basePath .publish
        $packagesPath = Join-Path $basePath .packages
        
        if (Test-Path $publishPath -PathType Container) {
            rm -rf $publishPath
        }
        if (Test-Path $packagesPath -PathType Container) {
            rm -rf $packagesPath
        } else {
            New-Item -Path $packagesPath -ItemType "directory"
        }
        
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
