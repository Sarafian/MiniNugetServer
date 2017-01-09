param(
    [Parameter(Mandatory=$false)]
    [switch]$RemoveDefaultWebSite,
    [Parameter(Mandatory=$false)]
    [int]$Port=80
)

Set-StrictMode -version latest

# Import IIS Administration Module
Import-module IISAdministration

#Remove Default Web Site
if($RemoveDefaultWebSite)
{
    Remove-IISSite -Name "Default Web Site" -Confirm:$false
}

$physicalPath=Join-Path $PSScriptRoot MiniNugetServer
$bindingInformation="*:$($Port):"
New-IISSite -Name "MiniNugetServer" -PhysicalPath $physicalPath -BindingInformation "*:$($Port):"
