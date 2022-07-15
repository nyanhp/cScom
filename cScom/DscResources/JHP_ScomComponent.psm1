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
        $status = Test-cScomInstallationStatus -ScomComponent $this.GetConfigurableDscProperties()
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
            'FirstManagementServer'
            {
                $parameters['DwDatabaseName'] = $this.DwDatabaseName
                $parameters['DwSqlInstancePort'] = $this.DwSqlInstancePort
                $parameters['DwSqlServerInstance'] = $this.DwSqlServerInstance
                $parameters['ManagementGroupName'] = $this.ManagementGroupName
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
            'AdditionalManagementServer'
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
            'ReportServer'
            {
                $parameters['ManagementServer'] = $this.ManagementServer
                $parameters['SRSInstance'] = $this.SRSInstance
                $parameters['DataReaderUser'] = $this.DataReader.UserName
                $parameters['DataReaderPassword'] = $this.DataReader.GetNetworkCredential().Password
            }
            'WebConsole'
            {
                $parameters['WebSiteName'] = $this.WebSiteName
                $parameters['ManagementServer'] = $this.ManagementServer
                $parameters['WebConsoleAuthorizationMode'] = $this.WebConsoleAuthorizationMode
            }
            'NativeConsole'
            {
                $parameters['InstallLocation'] = $this.InstallLocation
            }
        }

        $commandline = Get-cScomParameter @parameters -Uninstall:$($this.Ensure -eq 'Absent')
        $setupEchse = Get-ChildItem -Path $this.SourcePath -Filter setup.exe

        if (-not $setupEchse)
        {
            Write-Error -Message "Path $($this.SourcePath) is missing setup.exe"
            return
        }

        $obfuscatedCmdline = $commandline
        foreach ($pwdKey in $parameters.GetEnumerator())
        {
            if ($pwdKey.Key -notlike '*Password') { continue }
            $obfuscatedCmdline = $obfuscatedCmdline.Replace($pwdKey.Value, '******')
        }
        Write-Verbose -Message "Starting setup of SCOM $($this.Role): $($setupEchse.FullName) $commandLine"
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

    [Hashtable] GetConfigurableDscProperties() {
        # This method returns a hashtable of properties with two special workarounds
        # The hashtable will not include any properties marked as "NotConfigurable"
        # Any properties with a ValidateSet of "True","False" will beconverted to Boolean type
        # The intent is to simplify splatting to functions
        # Source: https://gist.github.com/mgreenegit/e3a9b4e136fc2d510cf87e20390daa44
        $DscProperties = @{}
        foreach ($property in [ScomComponent].GetProperties().Name) {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomComponent].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable) {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomComponent].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
                if ($validateSet) {
                    # Workaround for boolean types
                    if ($null -eq (Compare-Object @('True', 'False') $validateSet)) {
                        $value = [System.Convert]::ToBoolean($this.$property)
                    }
                }
                # Add property to new
                $DscProperties.add($property, $value)
            } 
        }
        return $DscProperties
    }
}