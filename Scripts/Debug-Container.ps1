param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("PowerShell","Cmd")]
    [string]$Cmd="Cmd"
)

Set-StrictMode -version latest

$imageName="asarafian/mininugetserver"
$dockerFilePath="$PSScriptRoot/../Source/MiniNugetServer"

# Build the image
$arguments=@(
    "build"
    "-t"
    $imageName
    "-f"
    "$dockerFilePath/MiniNugetServer.dockerfile"
    $dockerFilePath
)
& docker $arguments 2>&1

# Run the image and enter powershell
$arguments=@(
    "run"
    "--rm"
    "-it"
    $imageName
    $Cmd
)
& docker $arguments 2>&1
