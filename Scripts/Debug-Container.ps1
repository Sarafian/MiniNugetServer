param(
    [Parameter(Mandatory=$false)]
    [switch]$Remove=$false,
    [Parameter(Mandatory=$false)]
    [switch]$Build=$false,
    [Parameter(Mandatory=$false)]
    [ValidateSet("None","PowerShell","Cmd")]
    [string]$Start="None"
)

Set-StrictMode -version latest

$instancename="mininugetserver.debug"
$imageName="asarafian/mininugetserver"
$dockerFilePath="$PSScriptRoot/../Source"

if($Remove)
{
    $arguments=@(
        "rm"
        "-f"
        $instancename
    )
    & docker $arguments 2>&1
}

if($Build)
{
    $arguments=@(
        "build"
        "-t"
        $imageName
        "-f"
        "$dockerFilePath/MiniNugetServer.dockerfile"
        $dockerFilePath
    )
    & docker $arguments 2>&1
}

if($Start -ne "None")
{
    $arguments=@(
        "run"
        "--rm"
        "-it"
        "--name"
        $instancename
        $imageName
        $Start
    )
    & docker $arguments 2>&1

}