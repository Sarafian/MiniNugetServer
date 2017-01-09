FROM microsoft/windowsservercore

MAINTAINER Alex Sarafian

ADD MiniNugetServer/ /Container/MiniNugetServer
ADD https://github.com/Microsoft/iis-docker/blob/master/windowsservercore/ServiceMonitor.exe?raw=true /Container/ServiceMonitor.exe
COPY *.ps1 /Container/

RUN powershell -NoProfile -Command Add-WindowsFeature Web-Server; \
    powershell -NoProfile -Command Add-WindowsFeature NET-Framework-45-ASPNET; \
    powershell -NoProfile -Command Add-WindowsFeature Web-Asp-Net45; \
    powershell -NoProfile -Command Remove-Item -Recurse C:\inetpub\wwwroot\*; \
    powershell -NoProfile -File "C:\Container\New-Site.Docker.Run.ps1" -Port 80 -RemoveDefaultWebSite

# This instruction tells the container to listen on port 80. 
EXPOSE 80

# set environment variables
ENV apikey "mininugetserver"
ENV packagesPath "~/Packages"

CMD powershell -NoProfile -File "C:\Container\Start-ConfigurationServiceMonitor.Docker.Cmd.ps1" -ApiKey %apikey% -PackagesPath %packagesPath%