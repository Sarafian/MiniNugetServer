$imageName="asarafian/mininugetserver"

# Build the image
$arguments=@(
    "build"
    "-t"
    $imageName
    "-f"
    "$PSScriptRoot/MiniNugetServer.dockerfile"
    $PSScriptRoot
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
