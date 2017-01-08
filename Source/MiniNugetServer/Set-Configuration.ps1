param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    [Parameter(Mandatory=$false)]
    [string]$PackagesPath="~/Packages"
)

$webConfigPath=Join-Path $PSScriptRoot "MiniNugetServer\web.config"

[xml]$xml=Get-Content -Path $webConfigPath
$appSettings=$xml.configuration.appSettings.add
($appSettings|Where-Object -Property key -EQ apiKey).SetAttribute("value",$ApiKey)
($appSettings|Where-Object -Property key -EQ packagesPath).SetAttribute("value",$PackagesPath)
$xml.Save($webConfigPath)