Set-StrictMode -Version latest
$random=("abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()| Get-Random -Count 5) -join ""
$ProgressPreference="SilentlyContinue"
$instanceName="mininugetserver.pester.$random"
$testRepositoryName="mininugetserver.pester.$random"
$imageName="asarafian/mininugetserver"
$apikey="mininugetserver.pester.$random"
$packagesPath="C:\mininugetserver.pester.packages"
$testModuleName="MarkdownPS"
    
Remove-Item -Path $packagesPath -Force -Recurse -ErrorAction SilentlyContinue
$null=New-Item -Path $packagesPath -ItemType Directory
    
Describe "Docker Initialize" {
    It "Run" {
        $arguments=@(
            "run"
            "-d"
            "-e"
            "apikey=$apikey"
            "-e"
            "packagesPath=C:\Packages"
            "-v"
            "$($packagesPath):C:\Packages"
            "--name"
            $instanceName
            $imageName
        )
            
        { & docker $arguments 2>&1 } | Should Not throw
    }

}

Describe "PSRepository" {
    It "Register-PSRepository" {
        $ip=& docker inspect -f "{{ .NetworkSettings.Networks.nat.IPAddress }}" $instanceName
        $location="http://$ip/nuget/"
        Register-PSRepository -Name $testRepositoryName -SourceLocation $location -PublishLocation $location -InstallationPolicy Trusted
    }
    It "Find-Module Before Publish" {
        $module=Find-Module -Repository $testRepositoryName
        $module | Should BeNullOrEmpty
    }
    It "Publish-Module $testModuleName" {
        Save-Module -Name $testModuleName -Path $env:TEMP -Repository PSGallery
        $testModulePath=Join-Path $env:TEMP $testModuleName
        Publish-Module -Path $testModulePath -Repository $testRepositoryName -NuGetApiKey $apikey
    }
    It "Find-Module $testModuleName After Publish" {
        $module=Find-Module -Name $testModuleName -Repository $testRepositoryName
        $module | Should Not BeNullOrEmpty
    }
    It "Find-Module $testModuleName After clean" {
        Get-ChildItem -Path $packagesPath |Remove-Item -Force -Recurse
        $module=Find-Module -Repository $testRepositoryName
        $module | Should BeNullOrEmpty
    }
    It "Unregister-PSRepository" {
        Unregister-PSRepository -Name $testRepositoryName -ErrorAction SilentlyContinue
    }
}

Describe "Docker Cleanup" {
    It "RM" {
        $arguments=@(
            "rm"
            "-f"
            $instanceName
        )
            
        { & docker $arguments 2>&1 } | Should Not throw
    }

}

Remove-Item -Path $packagesPath -Force -Recurse -ErrorAction SilentlyContinue
