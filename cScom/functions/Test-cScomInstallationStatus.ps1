<#
.SYNOPSIS
    Test if SCOM components are installed
.DESCRIPTION
    Test if SCOM components are installed
.EXAMPLE
    Test-cScomInstallationStatus -ScomComponent @{Role = 'NativeConsole'}

    returns boolean result indicating status.
.PARAMETER ScomComponent
    Hashtable resembling the DSC class ScomComponent.
#>
function Test-cScomInstallationStatus
{
    [OutputType([Bool])]
    [CmdletBinding()]
    param
    (
        [hashtable]
        $ScomComponent
    )

    if ($ScomComponent.Role -eq [ScomRole]::FirstManagementServer -or $ScomComponent.Role -eq [ScomRole]::FirstManagementServer)
    {
        if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
        {
            return [bool](Get-Package -Name 'System Center Operations Manager Server' -ProviderName msi -ErrorAction SilentlyContinue)
        }

        return (Test-Path -Path (Join-Path -Path $ScomComponent.InstallLocation -ChildPath Server))
    }

    if ($ScomComponent.Role -eq [ScomRole]::NativeConsole)
    {
        if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
        {
            return [bool](Get-Package -Name 'System Center Operations Manager Console' -ProviderName msi -ErrorAction SilentlyContinue)
        }

        return (Test-Path -Path (Join-Path -Path $ScomComponent.InstallLocation -ChildPath Console))
    }

    if ($ScomComponent.Role -eq [ScomRole]::WebConsole)
    {
        $website = Get-Website -Name $ScomComponent.WebSiteName -ErrorAction SilentlyContinue
        if (-not $website) { return $false }
        return $true
    }

    if ($ScomComponent.Role -eq [ScomRole]::ReportServer)
    {
        if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
        {
            return [bool](Get-Package -Name 'System Center Operations Manager Reporting Server' -ProviderName msi -ErrorAction SilentlyContinue)
        }

        return (Test-Path -Path (Join-Path -Path $ScomComponent.InstallLocation -ChildPath Reporting))
    }
}
