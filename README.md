# Experimental Mini NuGet Server on Windows Container

At this stage, this repository is a proof of concept to build an ASP.NET (not .NET core) web application in a Windows Container. 
The web application I chose is a simple implementation of the a [Nuget Server](http://nugetserver.net/). 

Containerizing this [Nuget Server](http://nugetserver.net/) needs to address a couple of issues:

- How to drive `web.config` parameters such as `apiKey` during `docker run`. An alternative could be when building but I prefer the run option.
- Mapping the `packagesPath` parameter to an external volume.
- Can I run this on top of the nano image?

The research progress will be updated in the branches and the wiki pages.

# Source structure

Within [Source](Source) there is the `MiniNugetServer.sln` visual studio solution and the `MiniNugetServer.dockerfile` docker build file. 
Within [Automation](Automation) there is the PowerShell build script `Invoke-All.ps1` that through parameters does the following.

| Step | Dependency | Parameter | Description |
| ---- | ---------- | --------- | ----------- |
| Clean | | `-Clean` | Removes the Publish directory |
| Restore | | `-RestoreNuget` | Downloads the Nuget client if necessary and restores the packages |
| Build | Restore | `-MSBuild` | Builds and publishes the MiniNugetServer web site |
| Docker | Build | `-Docker` |  Build the container **asarafian/mininugetserver** |

To run all steps execute `.\Automation\Invoke-All.ps1 -Clean -RestoreNuget -MSBuild -Docker -ErrorAction Stop`. 
You can also debug each step as long as the dependency chain is respected.

# Run the container

Within [Scripts](Scripts) execute the `Start-MiniNugetServer.ps1` to start the container. 
If everything goes well it will produce the url that for the containerized MiniNugetServer

# Debug 

To help debug the docker build script and debug the container instance execute `.\Source\MiniNugetServer\Start-DockerDebug.ps1`. 
This will:

1. Build a container image.
1. Run the container image and start PowerShell by overriding the entrypoint.

# Goal 

My goal is to publish this container to **asarafian/mininugetserver** to help me and others quickly setup a dev/tested oriented nuget feed. 
My ultimate goal is to automate fully the build and publishing of the container and make it available to Azure and AWS windows containers.

# If you want to help...

Please submit your ideas in code or with issues. 
Don't forget to check the wiki pages to identify current progress.