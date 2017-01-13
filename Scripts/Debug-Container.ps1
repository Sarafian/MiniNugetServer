param(
    [Parameter(Mandatory=$true,ParameterSetName="WindowsServerCore")]
    [switch]$WindowsServer,
    [Parameter(Mandatory=$false,ParameterSetName="WindowsServerCore")]
    [switch]$NewInstance=$false,
    [Parameter(Mandatory=$false,ParameterSetName="MiniNugetServer")]
    [switch]$Remove=$false,
    [Parameter(Mandatory=$false,ParameterSetName="MiniNugetServer")]
    [switch]$Build=$false,
    [Parameter(Mandatory=$false,ParameterSetName="MiniNugetServer")]
    [Parameter(Mandatory=$false,ParameterSetName="WindowsServerCore")]
    [ValidateSet("None","PowerShell","Cmd")]
    [string]$Start="None"
)

Set-StrictMode -version latest

switch ($PSCmdlet.ParameterSetName)
{
    'WindowsServerCore' {
        $instancename="windowsservercore.debug.mininugetserver"
        $repositoryPath=Resolve-Path "$PSScriptRoot\.."
        if($WindowsServer)
        {
            if($NewInstance)
            {
                $arguments=@(
                    "run"
                    "-it"
                    "--rm"
                    "-v"
                    "$repositoryPath/:C:/Repository"
                    "--name"
                    $instancename
                    "microsoft/windowsservercore"
                    $Start
                )
            }
            else
            {
                $arguments=@(
                    "start"
                    $instancename
                )
            }
            & docker $arguments 2>&1
        }
    }
    'MiniNugetServer' {
        $instancename="mininugetserver.debug"
        $imageName="asarafian/mininugetserver"
        $dockerFolderPath=Resolve-Path -Path "$PSScriptRoot/../Source"
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
                "$dockerFolderPath\MiniNugetServer.dockerfile"
                $dockerFolderPath.Path
            )
            $arguments
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
    }
}

