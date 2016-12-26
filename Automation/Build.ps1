param(
    [Parameter(Mandatory=$false,ParameterSetName="Debug")]
    [ValidateSet("Debug","Release")]
    [string]$Configuration="Release"
)
$buildActivity="Build"
$msBuildPath="C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"


try
{
    #region Remove Publish folder
    Write-Progress -Activity $buildActivity -Status "Removing Publish folder"
    $publishPath="$PSScriptRoot\..\Publish"
    Remove-Item $publishPath -Force -Recurse -ErrorAction SilentlyContinue
    #endregion

    #region Build solution
    Write-Progress -Activity $buildActivity -Status "Building solution"
    $slnPath=Join-Path $sourcePath "MiniNugetServer\MiniNugetServer.sln"

    $arguments=@(
        "/p:Configuration=$Configuration"
        "/t:rebuild"
        "/p:FrameworkPathOverride=""C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6"""
        $slnPath
    )
    & $msBuildPath $arguments
    #endregion

    #region Publish web site
    Write-Progress -Activity $buildActivity -Status "Publishing project"
    $csprojPath=Join-Path $sourcePath "MiniNugetServer\MiniNugetServer\MiniNugetServer.csproj"
    $arguments=@(
        $csprojPath
        "/p:DeployOnBuild=true"
        "/p:PublishProfile=Docker"
        "/p:VisualStudioVersion=14.0"
    )
    & $msBuildPath $arguments
    #endregion

    #region Docker Build
    Write-Progress -Activity $buildActivity -Status "Building container"
    Copy-Item -Path "$sourcePath\MiniNugetServer\MiniNugetServer.dockerfile" -Destination $publishPath -Force
    #endregion

    $arguments=@(
        "build"
        "-t"
        "asarafian/mininugetserver"
        "-f"
        "$publishPath/MiniNugetServer.dockerfile"
        $publishPath
    )
    & docker $arguments

}
finally
{
}
