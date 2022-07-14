<#
.SYNOPSIS
    Return a formatted command line to install SCOM
.DESCRIPTION
    Return a formatted command line to install SCOM
.EXAMPLE
    Get-cScomParameter @parameters

    /install /silent /components:OMConsole /AcceptEndUserLicenseAgreement:"1" /EnableErrorReporting:"Never" /InstallLocation:"C:\Program Files\Microsoft System Center\Operations Manager" /SendCEIPReports:"0" /UseMicrosoftUpdate:"0"
#>
function Get-cScomParameter
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PsAvoidUsingPlaintextForPassword", "", Justification = "Nope")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingUsernameAndPasswordParams", "", Justification = "Nope")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Justification = "Parameters used programmatically")]
    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [Role]
        $Role,

        [string]
        $ManagementGroupName,

        [string]
        $SqlServerInstance,

        [string]
        $SqlInstancePort,

        [string]
        $DatabaseName,

        [string]
        $DwSqlServerInstance,

        [string]
        $InstallLocation,

        [string]
        $DwSqlInstancePort,
        [string]
        $DwDatabaseName,
        [string]
        $ActionAccountUser,
        [string]
        $ActionAccountPassword,
        [string]
        $DASAccountUser,
        [string]
        $DASAccountPassword,
        [string]
        $DataReaderUser,
        [string]
        $DataReaderPassword,
        [string]
        $DataWriterUser,
        [string]
        $DataWriterPassword,
        [string]
        $ManagementServer,
        [string]
        $WebSiteName,
        [string]
        $WebConsoleAuthorizationMode,
        [uint16]
        $WebConsoleUseSSL,
        [string]
        $SRSInstance,
        [uint16]
        $UseMicrosoftUpdate = 0,
        [switch]
        $Uninstall
    )

    $parameters = @{
        FirstManagementServer      = @{
            ManagementGroupName           = 'SCOM2019'
            ManagementServicePort         = '5723'
            SqlServerInstance             = ''
            SqlInstancePort               = '1433'
            DatabaseName                  = 'OperationsManager'
            DwSqlServerInstance           = ''
            InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
            DwSqlInstancePort             = '1433'
            DwDatabaseName                = 'OperationsManagerDW'
            ActionAccountUser             = 'OM19AA'
            ActionAccountPassword         = ''
            DASAccountUser                = 'OM19DAS' 
            DASAccountPassword            = ''
            DataReaderUser                = 'OM19READ'
            DataReaderPassword            = ''
            DataWriterUser                = 'OM19WRITE'
            DataWriterPassword            = ''
            EnableErrorReporting          = 'Never'
            SendCEIPReports               = '0'
            UseMicrosoftUpdate            = '0'
            AcceptEndUserLicenseAgreement = '1'     
        }

        AdditionalManagementServer = @{
            SqlServerInstance             = ''
            SqlInstancePort               = '1433'
            ManagementServicePort         = '5723'
            DatabaseName                  = 'OperationsManager'
            InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
            ActionAccountUser             = 'OM19AA'
            ActionAccountPassword         = ''
            DASAccountUser                = 'OM19DAS' 
            DASAccountPassword            = ''
            DataReaderUser                = 'OM19READ'
            DataReaderPassword            = ''
            DataWriterUser                = 'OM19WRITE'
            DataWriterPassword            = ''
            EnableErrorReporting          = 'Never'
            SendCEIPReports               = '0'
            AcceptEndUserLicenseAgreement = '1'
            UseMicrosoftUpdate            = '0'
        }

        NativeConsole              = @{
            EnableErrorReporting          = 'Never'
            InstallLocation               = 'C:\Program Files\Microsoft System Center\Operations Manager'
            SendCEIPReports               = '0'
            UseMicrosoftUpdate            = '0'
            AcceptEndUserLicenseAgreement = '1'
        }

        WebConsole                 = @{
            ManagementServer              = ''
            WebSiteName                   = 'Default Web Site'
            WebConsoleAuthorizationMode   = 'Mixed'
            WebConsoleUseSSL              = '0'
            SendCEIPReports               = '0'
            UseMicrosoftUpdate            = '0'
            AcceptEndUserLicenseAgreement = '1'
        }

        ReportServer               = @{
            ManagementServer              = ''
            SRSInstance                   = ''
            DataReaderUser                = 'OM19READ'
            DataReaderPassword            = ''
            SendODRReports                = '0'
            UseMicrosoftUpdate            = '0'
            AcceptEndUserLicenseAgreement = '1'
        }
    }

    $arguments = $parameters[$Role.ToString()].GetEnumerator() | Sort-Object Key | ForEach-Object {
        $value = $_.Value
        if ([string]::IsNullOrWhiteSpace($value) -and $PSBoundParameters.ContainsKey($_.Key))
        {
            $value = $PSBoundParameters[$_.Key]
        }
        '/{0}:"{1}"' -f $_.Key, $value
    }
    
    switch ($Role)
    {
        { $Role -in 'FirstManagementServer', 'AdditionalManagementServer' }
        { 
            if ($Uninstall.IsPresent) { '/uninstall /silent /components:OMServer'; break }
            "/install /silent /components:OMServer $arguments" 
        }
        'NativeConsole'
        { 
            if ($Uninstall.IsPresent) { '/uninstall /silent /components:OMConsole'; break }
            "/install /silent /components:OMConsole $arguments" 
        }
        'WebConsole'
        { 
            if ($Uninstall.IsPresent) { '/uninstall /silent /components:OMWebConsole'; break }
            "/install /silent /components:OMWebConsole $arguments" 
        }
        'ReportServer'
        { 
            if ($Uninstall.IsPresent) { '/uninstall /silent /components:OMReporting'; break }
            "/install /silent /components:OMReporting $arguments" 
        }
    }
}