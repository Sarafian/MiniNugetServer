param(
    [Parameter(Mandatory=$false)]
    [string]$ExternalPort="8080",
    [Parameter(Mandatory=$false)]
    [switch]$Rerun=$false,
    [Parameter(Mandatory=$false)]
    [string]$ApiKey="mininugetserver",
    [Parameter(Mandatory=$false)]
    [string]$PackagesPath="~/Packages"
)
Set-StrictMode -version latest

$name="mininugetserver"
$imageName="asarafian/mininugetserver"

#region remove instance

if($Rerun)
{
    $arguments=@(
        "stop"
        $name
    )
    & docker $arguments
    $arguments=@(
        "rm"
        "-f"
        $name
    )
    & docker $arguments
}

#endregion

#region start or run

$arguments=@(
    "ps"
    "-a"
    "--filter"
    "name=$name"
)
$filterResult=@(& docker $arguments 2>&1)
if($filterResult.Count -gt 1)
{
    $arguments=@(
        "start"
        $name
    )
}
else
{
    $arguments=@(
        "run"
        "-d"
        "-p"
        "$($ExternalPort):80"
        "-e"
        "apikey=$ApiKey"
        "-e"
        "packagesPath=$PackagesPath"
        "--name"
        $name
        $imageName
    )
}
& docker $arguments 2>&1

#endregion

#region test

$ip=& docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" $name
$url="http://$($ip)/"
if(Test-NetConnection -CommonTCPPort HTTP -ComputerName $ip -InformationLevel Quiet)
{
    Write-Host "$url is ready"
}
else
{
    Write-Error "$url is not working"
}

#endregion