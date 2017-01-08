$name="mininugetserver"
$imageName="asarafian/mininugetserver"
if((& docker ps -a --filter name=$name).Count -gt 1)
{
    & docker start $name
}
else
{
    & docker run -d --name $name $imageName
}

$ip=& docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" $name
$url="http://$($ip):8080/"
if(Test-NetConnection -CommonTCPPort HTTP -ComputerName $ip -InformationLevel Quiet)
{
    Write-Host "$url is ready"
}
else
{
    Write-Error "$url is not working"
}