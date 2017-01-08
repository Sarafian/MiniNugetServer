# The `FROM` instruction specifies the base image. You are
# extending the `microsoft/aspnet` image.
FROM microsoft/aspnet

# Next, this Dockerfile creates a directory for your application
RUN mkdir C:\Container\MiniNugetServer

# configure the new site in IIS.
RUN powershell -NoProfile -Command \
    Import-module IISAdministration; \
#	Remove-IISSite -Name "Default Web Site" -Confirm:$false; \
    New-IISSite -Name "MiniNugetServer" -PhysicalPath C:\Container\MiniNugetServer -BindingInformation "*:8080:"

# This instruction tells the container to listen on port 8080. 
EXPOSE 8080

# The final instruction copies the site you published earlier into the container.
ADD MiniNugetServer/ /Container/MiniNugetServer