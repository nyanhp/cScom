enum Ensure
{
    Present
    Absent
}

# Support for DSC v3, for what it's worth
class Reason
{
    [DscProperty()]
    [string] $Code
  
    [DscProperty()]
    [string] $Phrase
}

enum Role
{
    FirstManagementServer
    AdditionalManagementServer
    ReportServer
    WebConsole
    NativeConsole
}

[DscResource()]
class ScomComponent
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty(Key)] [Role] $Role
    [DscProperty(Mandatory)] [string] $SourcePath
    [DscProperty()] [System.String] $ManagementServer
    [DscProperty()] [System.String] $ManagementGroupName
    [DscProperty()] [System.Management.Automation.PSCredential] $DataReader
    [DscProperty()] [System.Management.Automation.PSCredential] $DataWriter
    [DscProperty()] [System.String] $SqlServerInstance
    [DscProperty()] [uint16] $SqlInstancePort = 1433
    [DscProperty()] [uint16] $DwSqlInstancePort = 1433
    [DscProperty()] [System.String] $DwSqlServerInstance
    [DscProperty()] [Ensure] $Ensure = 'Present'
    [DscProperty()] [System.String] $ProductKey
    [DscProperty()] [System.String] $InstallLocation = 'C:\Program Files\Microsoft System Center\Operations Manager'
    [DscProperty()] [System.UInt16] $ManagementServicePort = 5723
    [DscProperty()] [System.Management.Automation.PSCredential] $ActionAccount
    [DscProperty()] [System.Management.Automation.PSCredential] $DASAccount
    [DscProperty()] [System.String] $DatabaseName = "OperationsManager"
    [DscProperty()] [System.String] $DwDatabaseName = "OperationsManagerDW"
    [DscProperty()] [string] $WebSiteName = 'Default Web Site'
    [DscProperty()] [string] $WebConsoleAuthorizationMode = 'Mixed'
    [DscProperty()] [bool] $WebConsoleUseSSL = $false
    [DscProperty()] [bool] $UseMicrosoftUpdate = $true
    [DscProperty()] [string] $SRSInstance
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomComponent] Get()
    {
        $status = Test-cScomInstallationStatus -ScomComponent $this
        $returnTable = @{
            IsSingleInstance            = $this.IsSingleInstance
            Role                        = $this.Role
            SourcePath                  = $this.SourcePath
            ManagementServer            = $this.ManagementServer
            ManagementGroupName         = $this.ManagementGroupName
            DataReader                  = $this.DataReader
            DataWriter                  = $this.DataWriter
            SqlServerInstance           = $this.SqlServerInstance
            SqlInstancePort             = $this.SqlInstancePort
            DwSqlInstancePort           = $this.DwSqlInstancePort
            DwSqlServerInstance         = $this.DwSqlServerInstance
            Ensure                      = $this.Ensure
            ProductKey                  = $this.ProductKey
            InstallLocation             = $this.InstallLocation
            ManagementServicePort       = $this.ManagementServicePort
            ActionAccount               = $this.ActionAccount
            DASAccount                  = $this.DASAccount
            DatabaseName                = $this.DatabaseName
            DwDatabaseName              = $this.DwDatabaseName
            WebSiteName                 = $this.WebSiteName
            WebConsoleAuthorizationMode = $this.WebConsoleAuthorizationMode
            WebConsoleUseSSL            = $this.WebConsoleUseSSL
            UseMicrosoftUpdate          = $this.UseMicrosoftUpdate
            SRSInstance                 = $this.SRSInstance
        }

        if (-not $status -and $this.Ensure -eq 'Present')
        {
            $returnTable.Reasons = @(
                [Reason]@{
                    Code   = 'ScomComponent:ScomComponent:ProductNotInstalled'
                    Phrase = "SCOM component $($this.Role) is not installed, but it should be."
                }
            )
        }

        if ($status -and $this.Ensure -eq 'Absent')
        {
            $returnTable.Reasons = @(
                [Reason]@{
                    Code   = 'ScomComponent:ScomComponent:ProductInstalled'
                    Phrase = "SCOM component $($this.Role) is installed, but it should not be."
                }
            )
        }

        return $returnTable
    }

    [void] Set()
    {
        $parameters = @{
            Role = $this.Role
        }

        switch ($this.Role)
        {
            [Role]::FirstManagementServer
            {
                $parameters['DwDatabaseName'] = $this.DwDatabaseName
                $parameters['DwSqlInstancePort'] = $this.DwSqlInstancePort
                $parameters['DwSqlServerInstance'] = $this.DwSqlServerInstance
                $parameters['ManagementGroupName '] = $this.ManagementGroupName
                $parameters['ActionAccountPassword'] = $this.ActionAccount.GetNetworkCredential().Password
                $parameters['ActionAccountUser'] = $this.ActionAccount.UserName
                $parameters['DASAccountPassword'] = $this.DASAccount.GetNetworkCredential().Password
                $parameters['DASAccountUser'] = $this.DASAccount.UserName
                $parameters['DatabaseName'] = $this.DatabaseName
                $parameters['DataReaderPassword'] = $this.DataReader.GetNetworkCredential().Password
                $parameters['DataReaderUser'] = $this.DataReader.UserName
                $parameters['DataWriterPassword'] = $this.DataWriter.GetNetworkCredential().Password
                $parameters['DataWriterUser'] = $this.DataWriter.UserName
                $parameters['InstallLocation'] = $this.InstallLocation
                $parameters['ManagementServicePort'] = $this.ManagementServicePort
                $parameters['SqlInstancePort'] = $this.SqlInstancePort
                $parameters['SqlServerInstance'] = $this.SqlServerInstance
            }
            [Role]::AdditionalManagementServer
            {
                $parameters['ActionAccountPassword'] = $this.ActionAccount.GetNetworkCredential().Password
                $parameters['ActionAccountUser'] = $this.ActionAccount.UserName
                $parameters['DASAccountPassword'] = $this.DASAccount.GetNetworkCredential().Password
                $parameters['DASAccountUser'] = $this.DASAccount.UserName
                $parameters['DatabaseName'] = $this.DatabaseName
                $parameters['DataReaderPassword'] = $this.DataReader.GetNetworkCredential().Password
                $parameters['DataReaderUser'] = $this.DataReader.UserName
                $parameters['DataWriterPassword'] = $this.DataWriter.GetNetworkCredential().Password
                $parameters['DataWriterUser'] = $this.DataWriter.UserName
                $parameters['InstallLocation'] = $this.InstallLocation
                $parameters['ManagementServicePort'] = $this.ManagementServicePort
                $parameters['SqlInstancePort'] = $this.SqlInstancePort
                $parameters['SqlServerInstance'] = $this.SqlServerInstance
            }
            [Role]::ReportServer
            {
                $parameters['ManagementServer'] = $this.ManagementServer
                $parameters['SRSInstance'] = $this.SRSInstance
                $parameters['DataReaderUser'] = $this.DataReader.UserName
                $parameters['DataReaderPassword'] = $this.DataReader.GetNetworkCredential().Password
            }
            [Role]::WebConsole
            {
                $parameters['WebSiteName'] = $this.WebSiteName
                $parameters['ManagementServer'] = $this.ManagementServer
                $parameters['WebConsoleAuthorizationMode'] = $this.WebConsoleAuthorizationMode
            }
            [Role]::NativeConsole
            {
                $parameters['InstallLocation'] = $this.InstallLocation
            }
        }

        $commandline = Get-cScomParameter @parameters

        $setupEchse = Get-ChildItem -Path $this.InstallLocation -Filter setup.exe

        if (-not $setupEchse)
        {
            Write-Error -Message "Path $($this.InstallLocation) is missing setup.exe"
            return
        }

        $installation = Start-Process -Wait -PassThru -FilePath $setupEchse.FullName -ArgumentList $commandLine -WindowStyle Hidden

        if ($installation.ExitCode -eq 3010) { $global:DSCMachineStatus = 1; return }

        if ($installation.ExitCode -ne 0)
        {
            Write-Error -Message "Installation ran into an error. Exit code was $($installation.ExitCode)"
        }
    }

    [bool] Test()
    {
        $currentStatus = $this.Get()
        return ($currentStatus.Reasons.Count -eq 0) # Shrug-Emoji :)
    }
}