# Experimental Mini NuGet Server on Windows Container

At this stage, this repository is a proof of concept to build an ASP.NET (not .NET core) web application in a Windows Container. 
The web application I chose is a simple implementation of the a [Nuget Server](http://nugetserver.net/). 

Containerizing this [Nuget Server](http://nugetserver.net/) needs to address a couple of issues:

- How to drive `web.config` parameters such as `apiKey` during `docker run`. An alternative could be when building but I prefer the run option.
- Mapping the `packagesPath` parameter to an external volume.
- Can I run this on top of the nano image?

# Source structure

Within [Source](Source) there is the `MiniNugetServer.sln` visual studio solution and the `MiniNugetServer.dockerfile` docker build file. 
Within [Automation](Automation) there is the PowerShell build script `Build.ps1` that uses the `Publish` folder (excluded by `gitignore`) to build the container.

1. Clean the `Publish` folder.
1. Build the `MiniNugetServer.sln` solution.
1. Publish the `MiniNugetServer.csproj` web application.
1. Copy the docker build file `MiniNugetServer.dockerfile`.
1. Build the container.

# Goal 

My goal is to publish this container to **asarafian/mininugetserver** to help me and others quickly setup a dev/tested oriented nuget feed. 
My ultimate goal is to automate fully the build and publishing of the container and make it available to Azure and AWS windows containers.

# If you want to help...

Please submit your ideas in code or with issues. 