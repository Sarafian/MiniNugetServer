param(
    [Parameter(Mandatory=$false)]
    [switch]$Clean=$false,
    [Parameter(Mandatory=$false)]
    [switch]$RestoreNuget=$false,
    [Parameter(Mandatory=$false)]
    [switch]$MSBuild=$false,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug","Release")]
    [string]$MSBuildConfiguration="Release",
    [Parameter(Mandatory=$false)]
    [switch]$Docker=$false
)

#region Parameters

$activity="MiniNuGetServer"
$msBuildPath="C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
$sourcePath=Resolve-Path "$PSScriptRoot\..\Source"
$slnPath=Join-Path $sourcePath "MiniNugetServer\MiniNugetServer.sln"
$nugetUrl="https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
$publishPath="$PSScriptRoot\..\Publish"

#endregion

#region Clean Step

if($Clean)
{
    Write-Progress -Activity $activity -Status "Removing Publish folder"
    Remove-Item $publishPath -Force -Recurse -ErrorAction SilentlyContinue
}

#endregion

#region RestoreNuget Step

if($RestoreNuget)
{
    Write-Progress -Activity $activity -Status "Downloading NuGet client"
    $nugetPath=Join-Path $env:TEMP "nuget.exe"
    if(Test-Path -Path $nugetPath)
    {
        Write-Warning "Found $nugetPath. Skipping download..."
    }
    else
    {
        (New-Object System.Net.WebClient).DownloadFile($nugetUrl, $nugetPath)
    }

    Write-Progress -Activity $activity -Status "Restoring NuGet packages"
    $slnPath=Join-Path $sourcePath "MiniNugetServer\MiniNugetServer.sln"

    $arguments=@(
        "restore"
        $slnPath
    )
    & $nugetPath $arguments 2>&1
}

#endregion

#region MSBuild step

if($MSBuild)
{
    Write-Progress -Activity $activity -Status "Building solution"

    $arguments=@(
        "/p:Configuration=$MSBuildConfiguration"
        "/t:rebuild"
        "/p:FrameworkPathOverride=""C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6"""
        $slnPath
    )
    & $msBuildPath $arguments 2>&1

    Write-Progress -Activity $activity -Status "Publishing project"
    $csprojPath=Join-Path $sourcePath "MiniNugetServer\MiniNugetServer\MiniNugetServer.csproj"
    $arguments=@(
        $csprojPath
        "/p:DeployOnBuild=true"
        "/p:PublishProfile=Docker"
        "/p:VisualStudioVersion=14.0"
    )
    & $msBuildPath $arguments 2>&1
}

#endregion

#region Docker step

if($Docker)
{
    Write-Progress -Activity $activity -Status "Building container"
    Copy-Item -Path "$sourcePath\MiniNugetServer\MiniNugetServer.dockerfile" -Destination $publishPath -Force

    $arguments=@(
        "build"
        "-t"
        "asarafian/mininugetserver"
        "-f"
        "$publishPath/MiniNugetServer.dockerfile"
        $publishPath
    )
    & docker $arguments 2>&1
}

#endregion