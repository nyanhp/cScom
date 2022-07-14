function Resolve-cScomModule
{
    [CmdletBinding()]
    param ()
    
    if (Get-Module -Name OperationsManager) { return }

    $module = Get-Module -Name OperationsManager -ErrorAction SilentlyContinue -ListAvailable

    if (-not $module)
    {
        $module = Get-Module (Get-ChildItem -Path $env:ProgramFiles -Recurse -Filter OperationsManager.psd1 -ErrorAction SilentlyContinue | Select-Object -First 1) -ErrorAction SilentlyContinue
    }

    if (-not $module)
    {
        Write-Error -Exception ([System.IO.FileNotFoundException]::new('OperationsManager module not available.'))
        return
    }

    Import-Module -ModuleInfo $module -Force
}
