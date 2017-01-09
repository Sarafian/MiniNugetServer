# Experimental Mini NuGet Server on Windows Container

This repository is a proof of concept to build an ASP.NET (not .NET core) web application in a Windows Container. 
The web application I chose is a simple implementation of the a [Nuget Server](http://nugetserver.net/). 

Containerizing this [Nuget Server](http://nugetserver.net/) needs to address a couple of issues:

- How to drive `web.config` parameters such as `apiKey` during `docker run`. An alternative could be when building but I prefer the run option.
- Mapping the `packagesPath` parameter to an external volume.
- Can I run this on top of the nano image?

The research progress will be updated in the branches and the wiki pages.

# Goal 

My goal is to publish this container to **asarafian/mininugetserver** to help me and others quickly setup a dev/tested oriented nuget feed. 
My ultimate goal is to automate fully the build and publishing of the container and make it available to Azure and AWS windows containers.

# Source structure

Within [Source](Source) there is the `MiniNugetServer.sln` visual studio solution and the `MiniNugetServer.dockerfile` docker build file. 
Within [Automation](Automation) there is the PowerShell build script `Invoke-All.ps1` that through parameters does the following.

| Step | Dependency | Parameter | Description |
| ---- | ---------- | --------- | ----------- |
| Clean | | `-Clean` | Removes the Publish directory |
| Restore | | `-RestoreNuget` | Downloads the Nuget client if necessary and restores the packages |
| Build | Restore | `-MSBuild` | Builds and publishes the MiniNugetServer web site |
| Docker | Build | `-Docker` |  Build the container **asarafian/mininugetserver** |

To run all steps execute `.\Automation\Invoke-All.ps1 -All -ErrorAction Stop`. 
To run the same process step by step execute `.\Automation\Invoke-All.ps1 -Clean -RestoreNuget -MSBuild -Docker -ErrorAction Stop`. 

# Run the container

Within [Scripts](Scripts) execute the `Start-Container.ps1` to start the container. 
If everything goes well it will produce the url that for the containerized MiniNugetServer.

If you want to run manually then standard `docker run` can be used with option definition of environment parameters **apikey** and **packagesFolder**.

```text
& docker run -d -p 8080:80 --name mininugetserver asarafian/mininugetserver
& docker run -d -p 8080:80 -e apikey=mininugetserver -e packagesPath=~/Packages --name mininugetserver asarafian/mininugetserver
```

# Debug 

To help debug the docker build script and debug the container instance execute `.\Scripts\Debug-Container.ps1`. 
This will:

1. Build a container image using the source as is in the source directory.
1. Run the container image and start the shell. You can overwrite which shell to start by specifying the `-Cmd` parameter. 

This script is meant:
- To provide an overview of what happened during the build of the image.
- Execute manually any cmd. To see what will happen when running the image execute the `CMD` from the docker build file `MiniNugetServer.dockerfile`.

# If you want to help...

Please submit your ideas in code or with issues. 
Don't forget to check the wiki pages to identify current progress.