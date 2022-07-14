function Test-cScomInstallationStatus
{
    [OutputType([Bool])]
    [CmdletBinding()]
    param
    (
        [hashtable]
        $ScomComponent
    )

    if ($ScomComponent.Role -eq [Role]::FirstManagementServer -or $ScomComponent.Role -eq [Role]::FirstManagementServer)
    {
        if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
        {
            return [bool](Get-Package -Name 'System Center Operations Manager Server' -ProviderName Programs -ErrorAction SilentlyContinue)
        }

        return (Test-Path -Path (Join-Path -Path $ScomComponent.InstallLocation -ChildPath Server))
    }

    if ($ScomComponent.Role -eq [Role]::NativeConsole)
    {
        if (Get-Command -Name Get-Package -ErrorAction SilentlyContinue)
        {
            return [bool](Get-Package -Name 'System Center Operations Manager Console' -ProviderName Programs -ErrorAction SilentlyContinue)
        }

        return (Test-Path -Path (Join-Path -Path $ScomComponent.InstallLocation -ChildPath Console))
    }

    if ($ScomComponent.Role -eq [Role]::WebConsole)
    {
        $website = Get-Website -Name $ScomComponent.WebSiteName -ErrorAction SilentlyContinue
        if (-not $website) { return $false }
        return $true
    }

    if ($ScomComponent.Role -eq [Role]::ReportServer)
    {
        return $true
    }
}
