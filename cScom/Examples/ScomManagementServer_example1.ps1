configuration ScomManagementServerExample1
{
    Import-DscResource -ModuleName cScom -Name ScomManagementServer

    node $AllNodes.NodeName
    {
        ScomManagementServer $Node.NodeName
        {
            IsSingleInstance        = 'yes'
            SourcePath              = '\\contoso\InstallationSources\Scom\setup.exe'
            ManagementGroupName     = 'MG1'
            IsFirstManagementServer = $true
            Ensure                  = 'Present'
            ProductKey              = '555nase'
            DataReader              = $ConfigurationData.DomainCredential
            DataWriter              = $ConfigurationData.DomainCredential
            SetupCredential         = $ConfigurationData.DomainCredential
            SqlServerInstance       = 'SQL1'
            DwSqlServerInstance     = 'SQL1'
        }
    }
}

$configurationData = @{
    AllNodes         = @(
        @{
            NodeName                    = 'MG1'
            PsDscAllowPlainTextPassword = $true
        }
    )

    DomainCredential = [pscredential]::new('user', ('pass' | ConvertTo-SecureString -AsPlainText -Force))
}

ScomManagementServerExample1 -ConfigurationData $configurationData
