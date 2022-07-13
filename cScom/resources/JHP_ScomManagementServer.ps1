[DscResource()]
class ScomManagementServer
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty(Mandatory)] [string] $SourcePath
    [DscProperty(Mandatory)] [System.String] $ManagementGroupName
    [DscProperty(Mandatory)] [System.Boolean] $IsFirstManagementServer
    [DscProperty(Mandatory)] [System.Management.Automation.PSCredential] $DataReader
    [DscProperty(Mandatory)] [System.Management.Automation.PSCredential] $DataWriter
    [DscProperty(Mandatory)] [System.String] $SqlServerInstance
    [DscProperty(Mandatory)] [System.String] $DwSqlServerInstance
    [DscProperty()] [Ensure] $Ensure = 'Present'
    [DscProperty()] [System.Management.Automation.PSCredential] $SetupCredential
    [DscProperty()] [System.String] $ProductKey
    [DscProperty()] [System.String] $InstallPath = 'C:\Program Files\SCOM'
    [DscProperty()] [System.UInt16] $ManagementServicePort = 5723
    [DscProperty()] [System.Management.Automation.PSCredential] $ActionAccount
    [DscProperty()] [System.Management.Automation.PSCredential] $DASAccount
    [DscProperty()] [System.String] $DatabaseName = "OperationsManager"
    [DscProperty()] [System.UInt16] $DatabaseSize = 1000
    [DscProperty()] [System.String] $DwDatabaseName = "OperationsManagerDW"
    [DscProperty()] [System.UInt16] $DwDatabaseSize = 1000
    [DscProperty()] [System.Byte] $UseMicrosoftUpdate
    [DscProperty()] [System.Byte] $SendCEIPReports
    [DscProperty()] [ValidateSet("Never", "Queued", "Always")] [System.String] $EnableErrorReporting = "Never"
    [DscProperty()] [System.Byte] $SendODRReports
    [DscProperty(NotConfigurable)] [Reason] $Reason

    [ScomManagementServer] Get()
    {
        return @{}
    }

    [void] Set()
    {

    }

    [bool] Test()
    {
        return $false
    }
}