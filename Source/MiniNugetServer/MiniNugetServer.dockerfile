# The `FROM` instruction specifies the base image. You are
# extending the `microsoft/aspnet` image.
FROM microsoft/aspnet

# Next, this Dockerfile creates a directory for your application
RUN mkdir C:\MiniNugetServer

# configure the new site in IIS.
RUN powershell -NoProfile -Command \
    Import-module IISAdministration; \
    New-IISSite -Name "MiniNugetServer" -PhysicalPath C:\MiniNugetServer -BindingInformation "*:8080:"

# This instruction tells the container to listen on port 80. 
EXPOSE 8080

# The final instruction copies the site you published earlier into the container.
ADD MiniNugetServer/ /MiniNugetServer