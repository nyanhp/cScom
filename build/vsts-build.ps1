﻿<#
This script publishes the module to the gallery.
It expects as input an ApiKey authorized to publish the module.

Insert any build steps you may need to take before publishing it here.
#>
param (
	$ApiKey,
	
	$WorkingDirectory,
	
	$Repository = 'PSGallery',
	
	[switch]
	$LocalRepo,
	
	[switch]
	$SkipPublish,
	
	[switch]
	$AutoVersion
)

#region Handle Working Directory Defaults
if (-not $WorkingDirectory)
{
	if ($env:RELEASE_PRIMARYARTIFACTSOURCEALIAS)
	{
		$WorkingDirectory = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath $env:RELEASE_PRIMARYARTIFACTSOURCEALIAS
	}
	else { $WorkingDirectory = $env:SYSTEM_DEFAULTWORKINGDIRECTORY }
}
if (-not $WorkingDirectory) { $WorkingDirectory = Split-Path $PSScriptRoot }
#endregion Handle Working Directory Defaults

# Prepare publish folder
Write-Host "Creating and populating publishing directory"
$publishDir = New-Item -Path $WorkingDirectory -Name publish -ItemType Directory -Force
$moduleDir = New-Item -path (Join-Path $publishDir cScom) -Force -ItemType Directory
Copy-Item -Path "$($WorkingDirectory)\cScom\cScom.ps*1" -Destination $moduleDir.FullName -Force
Copy-Item -Path "$($WorkingDirectory)\cScom\Examples" -Destination $moduleDir.FullName -Force -Recurse
$theModule = Import-PowerShellDataFile -Path "$($publishDir.FullName)\cScom\cScom.psd1"
$ver = $theModule.ModuleVersion
if ($theModule.PrivateData.PSData.Prerelease)
{
	$ver = "$ver-$($theModule.PrivateData.PSData.Prerelease)"
}

#region Gather text data to compile
$text = @( )

# Gather commands
Get-ChildItem -Path "$($WorkingDirectory)\cScom\classes\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($WorkingDirectory)\cScom\resources\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($WorkingDirectory)\cScom\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}
Get-ChildItem -Path "$($WorkingDirectory)\cScom\internal\functions\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

# Gather scripts
Get-ChildItem -Path "$($WorkingDirectory)\cScom\internal\scripts\" -Recurse -File -Filter "*.ps1" | ForEach-Object {
	$text += [System.IO.File]::ReadAllText($_.FullName)
}

#region Update the psm1 file & Cleanup
[System.IO.File]::WriteAllText("$($publishDir.FullName)\cScom\cScom.psm1", ($text -join "`n`n"), [System.Text.Encoding]::UTF8)
#endregion Update the psm1 file & Cleanup

#region Updating the Module Version
if ($AutoVersion)
{
	Write-Host  "Updating module version numbers."
	try { $remoteVersion = (Find-Module 'cScom' -Repository $Repository -ErrorAction Stop -AllowPrerelease:$(-not [string]::IsNullOrWhiteSpace($theModule.PrivateData.PSData.Prerelease))).Version }
	catch
	{
		throw "Failed to access $($Repository) : $_"
	}
	if (-not $remoteVersion)
	{
		throw "Couldn't find cScom on repository $($Repository) : $_"
	}

	$parameter = @{
		Path = "$($publishDir.FullName)\cScom\cScom.psd1"
	}

	[Version]$remoteModuleVersion = $remoteVersion -replace '-\w+'
	[string]$prerelease = $remoteVersion -replace '[\d\.]+-'
	if ($prerelease)
	{
		$null = $prerelease -match '\d+'
		$number = [int]$Matches.0 + 1
		$parameter['Prerelease'] = $prerelease -replace '\d', $number
	}
	else
	{
		$newBuildNumber = $remoteModuleVersion.Build + 1
		[version]$localVersion = $theModule.ModuleVersion
		$parameter['ModuleVersion'] = "$($localVersion.Major).$($localVersion.Minor).$($newBuildNumber)"
	}
	Update-ModuleManifest @parameter
}
#endregion Updating the Module Version

#region Publish
if ($SkipPublish) { return }
if ($LocalRepo)
{
	# Dependencies must go first
	Write-Host  "Creating Nuget Package for module: PSFramework"
	New-PSMDModuleNugetPackage -ModulePath (Get-Module -Name PSFramework).ModuleBase -PackagePath .
	Write-Host  "Creating Nuget Package for module: cScom"
	New-PSMDModuleNugetPackage -ModulePath "$($publishDir.FullName)\cScom" -PackagePath .
}
else
{
	# Publish to Gallery
	Write-Host  "Publishing the cScom module to $($Repository)"
	Publish-Module -Path "$($publishDir.FullName)\cScom" -NuGetApiKey $ApiKey -Force -Repository $Repository
}
#endregion Publish