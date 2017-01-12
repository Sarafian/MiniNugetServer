param(
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$Clean=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$InstallMSBuildTools=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$RestoreNuget=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$MSBuild=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [ValidateSet("Debug","Release")]
    [string]$MSBuildConfiguration="Release",
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$Docker=$false,
    [Parameter(Mandatory=$true,ParameterSetName="Container")]
    [switch]$InContainer=$false
)

Set-StrictMode -version latest

#region Resolve All parameter set

if($PSCmdlet.ParameterSetName -eq "Container")
{
    $Clean=$true
    $InstallMSBuildTools=$true
    $RestoreNuget=$true
    $MSBuild=$true
    #$Docker=$true
}

#endregion

#region Parameters

$activity="MiniNuGetServer"
$msBuildToolsUrl="http://download.microsoft.com/download/4/3/3/4330912d-79ae-4037-8a55-7a8fc6b5eb68/buildtools_full.exe"
if($InstallMSBuildTools)
{
    $msBuildPath="C:\Program Files (x86)\MSBuild\14.0\Bin\amd64\MSBuild.exe"
}
else
{
    $msBuildPath="C:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe"
}
#$msBuildPath="C:\Windows\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe"
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

#region Download/Install MSBuildTools

if($InstallMSBuildTools)
{
    $msBuildToolsTempPath=Join-Path $env:TEMP buildtools_full.exe
    $msBuildToolsLogPath=Join-Path $env:TEMP microsoft-build-tools-2015.log
    
    if(Test-Path -Path $msBuildPath)
    {
        Write-Warning "Found $msBuildToolsTempPath. Skipping install..."
    }
    else
    {
        if(Test-Path $msBuildToolsTempPath)
        {
            Write-Warning "Found $msBuildToolsTempPath. Skipping download..."
        }
        else
        {
            Write-Progress -Activity $activity -Status "Downloading MSBuilt tools 2015"
            (New-Object System.Net.WebClient).DownloadFile($msBuildToolsUrl, $msBuildToolsTempPath)
        }
        Write-Progress -Activity $activity -Status "Installing MSBuilt tools 20151"
        $args=@(
            "/Passive"
            "/NoRestart"
            "/Log"
            $msBuildToolsLogPath
        )

        & $msBuildToolsTempPath $args 2>&1
    }
}

#endregion

#region RestoreNuget Step

if($RestoreNuget)
{
    $nugetPath=Join-Path $env:TEMP "nuget.exe"
    if(Test-Path -Path $nugetPath)
    {
        Write-Warning "Found $nugetPath. Skipping download..."
    }
    else
    {
        Write-Progress -Activity $activity -Status "Downloading NuGet client"
        (New-Object System.Net.WebClient).DownloadFile($nugetUrl, $nugetPath)
    }

    Write-Progress -Activity $activity -Status "Restoring NuGet packages"
    $slnPath=Join-Path $sourcePath "MiniNugetServer\MiniNugetServer.sln"

<#
    if($InstallMSBuildTools)
    {
        $env:Path+=Split-Path -Path $msBuildPath -Parent
    }
#>    
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