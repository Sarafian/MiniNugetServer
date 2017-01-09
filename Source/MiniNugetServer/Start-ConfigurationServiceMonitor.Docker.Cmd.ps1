param(
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    [Parameter(Mandatory=$true)]
    [string]$PackagesPath,
    [Parameter(Mandatory=$false)]
    [switch]$NoServiceMonitor=$false
)

Set-StrictMode -version latest

#region stop the iis sites

Import-Module IISAdministration
Get-IISSite|Stop-IISSite -Confirm:$false

#endregion

#region apply configuration values

$webConfigPath=Join-Path $PSScriptRoot "MiniNugetServer\web.config"

[xml]$xml=Get-Content -Path $webConfigPath
$appSettings=$xml.configuration.appSettings.add
($appSettings|Where-Object -Property key -EQ apiKey).SetAttribute("value",$ApiKey)
($appSettings|Where-Object -Property key -EQ packagesPath).SetAttribute("value",$PackagesPath)
$xml.Save($webConfigPath)

#endregion


#region start the iis sites

Get-IISSite|Start-IISSite

#endregion

#region Service Monitor

if(-not $NoServiceMonitor)
{
    & $PSScriptRoot\ServiceMonitor.exe w3svc
}

#endregion