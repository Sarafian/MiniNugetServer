param(
    [Parameter(Mandatory=$false)]
    [string]$ExternalPort="8080",
    [Parameter(Mandatory=$false)]
    [string]$ApiKey="mininugetserver",
    [Parameter(Mandatory=$false)]
    [string]$PackagesPath="~/Packages",
    [Parameter(Mandatory=$false)]
    [switch]$Remove=$false
)
Set-StrictMode -version latest

$instancename="mininugetserver"
$imageName="asarafian/mininugetserver"

#region Remove

if($Remove)
{
    $arguments=@(
        "rm"
        "-f"
        $instancename
    )
    & docker $arguments 2>&1
}

#endregion

#region start or run

$arguments=@(
    "ps"
    "-a"
    "--filter"
    "name=$instancename"
)
$filterResult=@(& docker $arguments 2>&1)
if($filterResult.Count -gt 1)
{
    $arguments=@(
        "start"
        $instancename
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
        $instancename
        $imageName
    )
}
& docker $arguments 2>&1

#endregion

#region test

$ip=& docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" $instancename
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