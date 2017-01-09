param(
    [Parameter(Mandatory=$false,ParameterSetName="By Step")]
    [switch]$Clean=$false,
    [Parameter(Mandatory=$false,ParameterSetName="By Step")]
    [switch]$RestoreNuget=$false,
    [Parameter(Mandatory=$false,ParameterSetName="By Step")]
    [switch]$MSBuild=$false,
    [Parameter(Mandatory=$false,ParameterSetName="By Step")]
    [Parameter(Mandatory=$false,ParameterSetName="All")]
    [ValidateSet("Debug","Release")]
    [string]$MSBuildConfiguration="Release",
    [Parameter(Mandatory=$false,ParameterSetName="By Step")]
    [switch]$Docker=$false,
    [Parameter(Mandatory=$true,ParameterSetName="All")]
    [switch]$All=$false
)

Set-StrictMode -version latest

#region Resolve All parameter set

if($PSCmdlet.ParameterSetName -eq "All")
{
    $Clean=$true
    $RestoreNuget=$true
    $MSBuild=$true
    $Docker=$true
}

#endregion

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
    Copy-Item -Path "$sourcePath\MiniNugetServer\*.ps1" -Destination $publishPath -Force

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