param(
    [Parameter(Mandatory=$true,ParameterSetName="Container")]
    [switch]$InContainer=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$Clean=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$InstallWindowsSDK=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$InstallMSBuildTools=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$RestoreNuget=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [switch]$MSBuild=$false,
    [Parameter(Mandatory=$false,ParameterSetName="Develop")]
    [ValidateSet("Debug","Release")]
    [string]$MSBuildConfiguration="Release"
)

Set-StrictMode -version latest

#region Resolve All parameter set

if($PSCmdlet.ParameterSetName -eq "Container")
{
    $Clean=$true
    $InstallWindowsSDK=$true
    $InstallMSBuildTools=$true
    $RestoreNuget=$true
    $MSBuild=$true
}

#endregion

#region Parameters

$activity="MiniNuGetServer"
# https://chocolatey.org/packages/windows-sdk-10.0
$windowsSDKUrl="http://download.microsoft.com/download/E/1/F/E1F1E61E-F3C6-4420-A916-FB7C47FBC89E/standalonesdk/sdksetup.exe"
# https://chocolatey.org/packages/microsoft-build-tools
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

#region Download/Install WindowsSDK

if($InstallWindowsSDK)
{
    $windowsSDKTempPath=Join-Path $env:TEMP sdk_setup.exe
    $windowsSDKLogPath=Join-Path $env:TEMP microsoft-build-tools-2015.log
    $netFrameworkSDLPath="Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.6\"

    if(Test-Path -Path $netFrameworkSDLPath)
    {
        Write-Warning "Found $netFrameworkSDLPath. Skipping install..."
    }
    else
    {
        if(Test-Path $windowsSDKTempPath)
        {
            Write-Warning "Found $windowsSDKTempPath. Skipping download..."
        }
        else
        {
            Write-Progress -Activity $activity -Status "Downloading Microsoft Windows SDK for Windows 10 and .NET Framework 4.6"
            (New-Object System.Net.WebClient).DownloadFile($windowsSDKUrl, $windowsSDKTempPath)
        }
        Write-Progress -Activity $activity -Status "Installing Microsoft Windows SDK for Windows 10 and .NET Framework 4.6"
        $args=@(
            "/Quiet"
            "/NoRestart"
            "/Log"
            $windowsSDKLogPath
        )

        & $windowsSDKTempPath $args 2>&1
    }
}

#endregion

#region Download/Install MSBuildTools

if($InstallMSBuildTools)
{
    $msBuildToolsTempPath=Join-Path $env:TEMP buildtools_full.exe
    $msBuildToolsLogPath=Join-Path $env:TEMP microsoft-build-tools-2015.log
    
    if(Test-Path -Path $msBuildPath)
    {
        Write-Warning "Found $msBuildPath. Skipping install..."
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
        Write-Progress -Activity $activity -Status "Installing MSBuilt tools 2015"
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

#region Initialize Environment

if(($env:Path -split ";") -notcontains $msBuildPath)
{
    $env:Path+=";"+(Split-Path -Path $msBuildPath -Parent)
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

    Copy-Item -Path "$sourcePath\MiniNugetServer\*Docker*.ps1" -Destination $publishPath -Force
}

#endregion