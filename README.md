# Experimental Mini NuGet Server on Windows Container

This repository is a proof of concept to build an ASP.NET (not .NET core) web application in a Windows Container. 
The web application I chose is a simple implementation of the a [Nuget Server](http://nugetserver.net/). 

Containerizing this [Nuget Server](http://nugetserver.net/) needs to address a couple of issues:

- How to drive `web.config` parameters such as `apiKey` during `docker run`. An alternative could be when building but I prefer the run option.
- Mapping the `packagesPath` parameter to an external volume.
- Can I run this on top of the nano image?

**Use the wiki pages to track the progress and answers to these questions**.

# Goal 

My goal is to publish this container to **asarafian/mininugetserver** to help me and others quickly setup a dev/tested oriented nuget feed. 
My ultimate goal is to automate fully the build and publishing of the container and make it available to Azure and AWS windows containers.

# Docker hub

Container is **available** on [asarafian/mininugetserver](https://hub.docker.com/r/asarafian/mininugetserver/).

# Source structure

Within [Source](Source) there is the a Visual Studio 2015 solution that is in effect an empty web application with reference to the [Nuget.Server](https://www.nuget.org/packages/NuGet.Server/) package. 
All files in the repository favor debugging and troubleshooting. 

The docker file is self contained. 
That means it will install all necessary tools to build and publish the solution from within the container. 

# Build the container

To build the container manually execute `.\Scripts\Debug-Container.ps1 -Build -ErrorAction Stop`.

# Run the container

Within [Scripts](Scripts) execute the `Start-Container.ps1` to start the container. 
If everything goes well it will produce the url that for the containerized MiniNugetServer.

If you want to run manually then standard `docker run` can be used with option definition of environment parameters **apikey** and **packagesFolder**. Examples:

- Default run: `docker run -d -p 8080:80 --name mininugetserver asarafian/mininugetserver`
- Specify **apikey** and/or **packagesFolder**: `docker run -d -p 8080:80 -e apikey=mininugetserver -e packagesPath=~/Packages --name mininugetserver asarafian/mininugetserver`
- Use `C:\Shared\Packages` on the host as the **packagesFolder** (`C:\Packages` within the container) by mounting volumes: `docker run -d -p 8080:80 -v C:/Shared/Packages/:C:/Packages -e apikey=mininugetserver -e packagesPath=C:/Packages --name mininugetserver asarafian/mininugetserver`

## Scale the container

To scale the containers you can use define docker compose configuration file referencing the [asarafian/mininugetserver](https://hub.docker.com/r/asarafian/mininugetserver/). 
To make sure they all behave the same and reference the same packages folder, define the **apikey** and/or **packagesFolder** environment variables.
The **packagesFolder** folder must specify to a common folder on the host that needs to be mounted to each container.

This is an example docker-compose file

```text
version: '2.1'

services:
  mininugetserver:
    image: asarafian/mininugetserver
    environment:
      apikey: "mininugetserver"
      packagesPath: "C:\Packages"
    volumes:
      - C:\MiniNuGetServer\Packages/:C:\Packages

networks:
  default:
    external:
      name: nat
```

To launch scale with e.g. 2 `mininugetserver` instances execute `docker-compose scale mininugetserver=2`.

# Debug 

To help tests within a container execute `.\Scripts\Debug-Container.ps1 -WindowsServer -Start cmd -ErrorAction Stop`. 
This will start a **microsoft/windowsservercore** instance with the shell. 
What is important is that withing the instance the "C:\Repository" will point to the root of the repository. 
To debug, copy any fragment from the docker file and execute within the container.

# Pester tests

Assuming the image for **asarafian/mininugetserver:latest** is built the [Test-All.ps1](Source\Pester\Test-All.ps1) will execute and test the following sequence:

1. Prepare a temporary packages folder to mount as volume for the target **packagesFolder** when running the **asarafian/mininugetserver** container.
1. Prepare a random string to use as the target **apiKey** when running the **asarafian/mininugetserver** container.
1. Test that container can run. User `docker run`  and acquire the IP. Acquire also the IP address.
1. Register the NuGet repository. Use `Register-PSRepository`.
1. Test the availability of the nuget server. Use `Find-Module`.
1. Test that a publish operation is possible (implicit test that the **apiKey** was correctly configured). Use `Save-Module` and `Publish-Module`.
1. Empty the mounted **packagesFolder**. This will remove all packages from the NuGet server.
1. Test the availability of the nuget server. Use `Find-Module`.
1. Test that the **packagesFolder** was correctly configured. Use `Find-Module`.
1. Cleanup.

# If you want to help...

Please submit your ideas in code or with issues. 
Don't forget to check the wiki pages to identify current progress.
