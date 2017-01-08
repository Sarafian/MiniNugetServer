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
    "--entrypoint=powershell"
    $imageName
)
& docker $arguments 2>&1
