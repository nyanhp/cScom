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

function Get-Resource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('yes')]
        [string]
        $IsSingleInstance,
        [Parameter(Mandatory)]
        [Role] $Role,
        [Parameter(Mandatory)]
        [string]
        $SourcePath,
        [System.String]
        $ManagementServer,
        [System.String]
        $ManagementGroupName,
        [System.Management.Automation.PSCredential]
        $DataReader,
        [System.Management.Automation.PSCredential]
        $DataWriter,
        [System.String]
        $SqlServerInstance,
        [uint16]
        $SqlInstancePort,
        [uint16]
        $DwSqlInstancePort,
        [System.String]
        $DwSqlServerInstance,
        [Ensure]
        $Ensure,
        [System.String]
        $ProductKey,
        [System.String]
        $InstallLocation,
        [System.UInt16]
        $ManagementServicePort,
        [System.Management.Automation.PSCredential]
        $ActionAccount,
        [System.Management.Automation.PSCredential]
        $DASAccount,
        [System.String]
        $DatabaseName,
        [System.String]
        $DwDatabaseName,
        [string]
        $WebSiteName,
        [string]
        $WebConsoleAuthorizationMode,
        [bool]
        $WebConsoleUseSSL,
        [bool]
        $UseMicrosoftUpdate,
        [string]
        $SRSInstance
    )

    $status = Test-cScomInstallationStatus -ScomComponent $PSBoundParameters

    $returnTable = @{
        IsSingleInstance            = $IsSingleInstance
        Role                        = $Role
        SourcePath                  = $SourcePath
        ManagementServer            = $ManagementServer
        ManagementGroupName         = $ManagementGroupName
        DataReader                  = $DataReader
        DataWriter                  = $DataWriter
        SqlServerInstance           = $SqlServerInstance
        SqlInstancePort             = $SqlInstancePort
        DwSqlInstancePort           = $DwSqlInstancePort
        DwSqlServerInstance         = $DwSqlServerInstance
        Ensure                      = $Ensure
        ProductKey                  = $ProductKey
        InstallLocation             = $InstallLocation
        ManagementServicePort       = $ManagementServicePort
        ActionAccount               = $ActionAccount
        DASAccount                  = $DASAccount
        DatabaseName                = $DatabaseName
        DwDatabaseName              = $DwDatabaseName
        WebSiteName                 = $WebSiteName
        WebConsoleAuthorizationMode = $WebConsoleAuthorizationMode
        WebConsoleUseSSL            = $WebConsoleUseSSL
        UseMicrosoftUpdate          = $UseMicrosoftUpdate
        SRSInstance                 = $SRSInstance
    }

    if (-not $status -and $Ensure -eq 'Present')
    {
        $returnTable.Reasons = @(
            [Reason]@{
                Code   = 'ScomComponent:ScomComponent:ProductNotInstalled'
                Phrase = "SCOM component $($Role) is not installed, but it should be."
            }
        )
    }

    if ($status -and $Ensure -eq 'Absent')
    {
        $returnTable.Reasons = @(
            [Reason]@{
                Code   = 'ScomComponent:ScomComponent:ProductInstalled'
                Phrase = "SCOM component $($Role) is installed, but it should not be."
            }
        )
    }

    return $returnTable
}

function Set-Resource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('yes')]
        [string]
        $IsSingleInstance,
        [Parameter(Mandatory)]
        [Role] $Role,
        [Parameter(Mandatory)]
        [string]
        $SourcePath,
        [System.String]
        $ManagementServer,
        [System.String]
        $ManagementGroupName,
        [System.Management.Automation.PSCredential]
        $DataReader,
        [System.Management.Automation.PSCredential]
        $DataWriter,
        [System.String]
        $SqlServerInstance,
        [uint16]
        $SqlInstancePort,
        [uint16]
        $DwSqlInstancePort,
        [System.String]
        $DwSqlServerInstance,
        [Ensure]
        $Ensure,
        [System.String]
        $ProductKey,
        [System.String]
        $InstallLocation,
        [System.UInt16]
        $ManagementServicePort,
        [System.Management.Automation.PSCredential]
        $ActionAccount,
        [System.Management.Automation.PSCredential]
        $DASAccount,
        [System.String]
        $DatabaseName,
        [System.String]
        $DwDatabaseName,
        [string]
        $WebSiteName,
        [string]
        $WebConsoleAuthorizationMode,
        [bool]
        $WebConsoleUseSSL,
        [bool]
        $UseMicrosoftUpdate,
        [string]
        $SRSInstance
    )
    $parameters = @{
        Role = $Role
    }

    switch ($Role)
    {
        'FirstManagementServer'
        {
            $parameters['DwDatabaseName'] = $DwDatabaseName
            $parameters['DwSqlInstancePort'] = $DwSqlInstancePort
            $parameters['DwSqlServerInstance'] = $DwSqlServerInstance
            $parameters['ManagementGroupName'] = $ManagementGroupName
            $parameters['ActionAccountPassword'] = $ActionAccount.GetNetworkCredential().Password
            $parameters['ActionAccountUser'] = $ActionAccount.UserName
            $parameters['DASAccountPassword'] = $DASAccount.GetNetworkCredential().Password
            $parameters['DASAccountUser'] = $DASAccount.UserName
            $parameters['DatabaseName'] = $DatabaseName
            $parameters['DataReaderPassword'] = $DataReader.GetNetworkCredential().Password
            $parameters['DataReaderUser'] = $DataReader.UserName
            $parameters['DataWriterPassword'] = $DataWriter.GetNetworkCredential().Password
            $parameters['DataWriterUser'] = $DataWriter.UserName
            $parameters['InstallLocation'] = $InstallLocation
            $parameters['ManagementServicePort'] = $ManagementServicePort
            $parameters['SqlInstancePort'] = $SqlInstancePort
            $parameters['SqlServerInstance'] = $SqlServerInstance
        }
        'AdditionalManagementServer'
        {
            $parameters['ActionAccountPassword'] = $ActionAccount.GetNetworkCredential().Password
            $parameters['ActionAccountUser'] = $ActionAccount.UserName
            $parameters['DASAccountPassword'] = $DASAccount.GetNetworkCredential().Password
            $parameters['DASAccountUser'] = $DASAccount.UserName
            $parameters['DatabaseName'] = $DatabaseName
            $parameters['DataReaderPassword'] = $DataReader.GetNetworkCredential().Password
            $parameters['DataReaderUser'] = $DataReader.UserName
            $parameters['DataWriterPassword'] = $DataWriter.GetNetworkCredential().Password
            $parameters['DataWriterUser'] = $DataWriter.UserName
            $parameters['InstallLocation'] = $InstallLocation
            $parameters['ManagementServicePort'] = $ManagementServicePort
            $parameters['SqlInstancePort'] = $SqlInstancePort
            $parameters['SqlServerInstance'] = $SqlServerInstance
        }
        'ReportServer'
        {
            $parameters['ManagementServer'] = $ManagementServer
            $parameters['SRSInstance'] = $SRSInstance
            $parameters['DataReaderUser'] = $DataReader.UserName
            $parameters['DataReaderPassword'] = $DataReader.GetNetworkCredential().Password
        }
        'WebConsole'
        {
            $parameters['WebSiteName'] = $WebSiteName
            $parameters['ManagementServer'] = $ManagementServer
            $parameters['WebConsoleAuthorizationMode'] = $WebConsoleAuthorizationMode
        }
        'NativeConsole'
        {
            $parameters['InstallLocation'] = $InstallLocation
        }
    }

    $commandline = Get-cScomParameter @parameters -Uninstall:$($Ensure -eq 'Absent')
    $setupEchse = Get-ChildItem -Path $SourcePath -Filter setup.exe

    if (-not $setupEchse)
    {
        Write-Error -Message "Path $($SourcePath) is missing setup.exe"
        return
    }

    $obfuscatedCmdline = $commandline
    foreach ($pwdKey in $parameters.GetEnumerator())
    {
        if ($pwdKey.Key -notlike '*Password') { continue }
        $obfuscatedCmdline = $obfuscatedCmdline.Replace($pwdKey.Value, '******')
    }
    Write-Verbose -Message "Starting setup of SCOM $($Role): $($setupEchse.FullName) $commandLine"
    $installation = Start-Process -Wait -PassThru -FilePath $setupEchse.FullName -ArgumentList $commandLine -WindowStyle Hidden

    if ($installation.ExitCode -eq 3010) { $global:DSCMachineStatus = 1; return }

    if ($installation.ExitCode -ne 0)
    {
        Write-Error -Message "Installation ran into an error. Exit code was $($installation.ExitCode)"
    }
}

function Test-Resource
{
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('yes')]
        [string]
        $IsSingleInstance,
        [Parameter(Mandatory)]
        [Role] $Role,
        [Parameter(Mandatory)]
        [string]
        $SourcePath,
        [System.String]
        $ManagementServer,
        [System.String]
        $ManagementGroupName,
        [System.Management.Automation.PSCredential]
        $DataReader,
        [System.Management.Automation.PSCredential]
        $DataWriter,
        [System.String]
        $SqlServerInstance,
        [uint16]
        $SqlInstancePort,
        [uint16]
        $DwSqlInstancePort,
        [System.String]
        $DwSqlServerInstance,
        [Ensure]
        $Ensure,
        [System.String]
        $ProductKey,
        [System.String]
        $InstallLocation,
        [System.UInt16]
        $ManagementServicePort,
        [System.Management.Automation.PSCredential]
        $ActionAccount,
        [System.Management.Automation.PSCredential]
        $DASAccount,
        [System.String]
        $DatabaseName,
        [System.String]
        $DwDatabaseName,
        [string]
        $WebSiteName,
        [string]
        $WebConsoleAuthorizationMode,
        [bool]
        $WebConsoleUseSSL,
        [bool]
        $UseMicrosoftUpdate,
        [string]
        $SRSInstance
    )

    return ($(Get-Resource @PSBoundParameters).Reasons.Count -eq 0)
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
    [DscProperty()] [uint16] $SqlInstancePort
    [DscProperty()] [uint16] $DwSqlInstancePort
    [DscProperty()] [System.String] $DwSqlServerInstance
    [DscProperty()] [Ensure] $Ensure
    [DscProperty()] [System.String] $ProductKey
    [DscProperty()] [System.String] $InstallLocation
    [DscProperty()] [System.UInt16] $ManagementServicePort
    [DscProperty()] [System.Management.Automation.PSCredential] $ActionAccount
    [DscProperty()] [System.Management.Automation.PSCredential] $DASAccount
    [DscProperty()] [System.String] $DatabaseName
    [DscProperty()] [System.String] $DwDatabaseName
    [DscProperty()] [string] $WebSiteName
    [DscProperty()] [string] $WebConsoleAuthorizationMode
    [DscProperty()] [bool] $WebConsoleUseSSL
    [DscProperty()] [bool] $UseMicrosoftUpdate
    [DscProperty()] [string] $SRSInstance
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    ScomComponent ()
    {
        $this.IsSingleInstance = 'yes'
        $this.InstallLocation = 'C:\Program Files\Microsoft System Center\Operations Manager'
        $this.Ensure = 'Present'
        $this.DatabaseName = "OperationsManager"
        $this.DwDatabaseName = "OperationsManagerDW"
        $this.WebSiteName = 'Default Web Site'
        $this.WebConsoleAuthorizationMode = 'Mixed'
        $this.WebConsoleUseSSL = $false
        $this.UseMicrosoftUpdate = $true
        $this.SqlInstancePort = 1433
        $this.DwSqlInstancePort = 1433
        $this.ManagementServicePort = 5723
    }

    [ScomComponent] Get()
    {
        $parameter = Sync-Parameter -Command (Get-Command Get-Resource) -Parameters $this.GetConfigurableDscProperties()
        return (Get-Resource @parameter)        
    }

    [void] Set()
    {
        $parameter = Sync-Parameter -Command (Get-Command Set-Resource) -Parameters $this.GetConfigurableDscProperties()
        Set-Resource @parameter        
    }

    [bool] Test()
    {
        $parameter = Sync-Parameter -Command (Get-Command Test-Resource) -Parameters $this.GetConfigurableDscProperties()
        return (Test-Resource @parameter)
    }

    [Hashtable] GetConfigurableDscProperties()
    {
        # This method returns a hashtable of properties with two special workarounds
        # The hashtable will not include any properties marked as "NotConfigurable"
        # Any properties with a ValidateSet of "True","False" will beconverted to Boolean type
        # The intent is to simplify splatting to functions
        # Source: https://gist.github.com/mgreenegit/e3a9b4e136fc2d510cf87e20390daa44
        $DscProperties = @{}
        foreach ($property in [ScomComponent].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomComponent].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomComponent].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
                if ($validateSet)
                {
                    # Workaround for boolean types
                    if ($null -eq (Compare-Object @('True', 'False') $validateSet))
                    {
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