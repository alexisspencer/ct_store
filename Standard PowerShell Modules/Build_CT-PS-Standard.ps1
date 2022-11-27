md NuGetPublish

Register-PSRepository -Name Local_Nuget_Feed -SourceLocation "$($PSScriptRoot)\NuGetPublish" -PublishLocation "$($PSScriptRoot)\NuGetPublish" -InstallationPolicy Trusted
#(To Remove:  Unregister-PSRepository -Name Local_Nuget_Feed)

#--- Verift/Show all PS Repository
Get-PSRepository
 
$Locations = Get-ChildItem -Directory | Select-Object Name

$GridArguments = @{
    OutputMode = 'Single'
    Title      = 'Please select the module folder and click OK'
}

$ModuleName = $Locations | Out-GridView @GridArguments | foreach { $_.Name }

cd $ModuleName

nuget spec CT-PS-Standard -Force

$ModuleVersion = Read-Host "Please enter module version number"

((Get-Content -path ".\$($ModuleName).nuspec" -Raw) -replace '1.0.0',$ModuleVersion) | Set-Content -Path ".\$($ModuleName).nuspec"

((Get-Content -path ".\$($ModuleName).nuspec" -Raw) -replace 'http://project_url_here_or_delete_this_line/','https://dev.azure.com/ct-itops-dev/Standard%20Template%20PS%20Modules') | Set-Content -Path ".\$($ModuleName).nuspec"
((Get-Content -path ".\$($ModuleName).nuspec" -Raw) -replace 'Package description','CT Module') | Set-Content -Path ".\$($ModuleName).nuspec"
((Get-Content -path ".\$($ModuleName).nuspec" -Raw) -replace 'Summary of changes made in this release of the package','$($ModuleName)') | Set-Content -Path ".\$($ModuleName).nuspec"
((Get-Content -path ".\$($ModuleName).nuspec" -Raw) -replace 'Tag1 Tag2','') | Set-Content -Path ".\$($ModuleName).nuspec"
((Get-Content -path ".\$($ModuleName).nuspec" -Raw) -replace '1.0.0',$ModuleVersion) | Set-Content -Path ".\$($ModuleName).nuspec"
nuget pack $ModuleName.nuspec


#--- Create and Install your Powershell Module as a NuGet Package ans save into the Nuget Package Repo/Feed
Publish-Module -Path .\$ModuleName -Repository Local_Nuget_Feed -NuGetApiKey 'Pacemaker_Skinning_Gigahertz9'
#(The .nupkg file is created here: c:\nuget\publish)

#-- List Packages in Repository
nuget list -source "$($PSScriptRoot)\NuGetPublish"

#-- Delete Package
nuget delete $ModuleName $ModuleVersion -source "$($PSScriptRoot)\NuGetPublish"

#--- Install your Powershell module from the .nupkg file you just created
#--- In an Elevated Powershell console:
Install-Package $ModuleName

#-- Check Nuget Package Version After Installation
get-package | where-object {$_.name -match '$($ModuleName)'}

#--- Test Loading/Calling a Function from your PS Module
#MyFunction

#--- List all functions in your PSM1 module
#Get-Command -Module MyModuleName

#--- Verify the correct version of your module and manifest files were installed in the Global Modules Folder here:
#C:\Program Files\WindowsPowerShell\Modules\MyModuleName