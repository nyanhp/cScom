# cScom

Class-based DSC resources to manage SCOM components as well as install SCOM. Looking for a schema-based (MOF) resource instead? Go to <https://github.com/dsccommunity/xscom>.

## Resources

### ScomAgentApprovalSetting

Configure the Agent Approval Setting for the management group. Select between AutoApprove, AutoReject and Pending.

#### Parameters:
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `ApprovalType` [string] ***Mandatory***: Possible Values: (AutoApprove,AutoReject,Pending) Approval type for new agents

### ScomAlertResolutionSetting

Configure the alert resolution setting.

#### Parameters:
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `HealthyAlertAutoResolveDays` [Int32]: Number of days after which healthy alerts are automatically resolved
- `AlertAutoResolveDays` [Int32]: Number of days after which alerts are automatically resolved

### ScomComponent

This module expects some sanity in your choices when using the cScomComponent resource. This resource is
used for the installation or removal of **all** SCOM components. The possible combinations of parameters
are not validated. Rather, it is expected that you at least in principle know which parameters SCOM expects.
For your reference, these can be reviewed here: <https://docs.microsoft.com/en-us/system-center/scom/install-using-cmdline?view=sc-om-2022>

#### Parameters:
- `SourcePath` [string] ***Mandatory***: Directory containing the extraced SCOM setup files
- `Role` [string] ***Mandatory***: Possible Values: (AdditionalManagementServer,FirstManagementServer,NativeConsole,ReportServer,WebConsole) Role of this system
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `SqlInstancePort` [UInt16]: Port of the SQL instance
- `ProductKey` [string]: Product key to configure
- `ManagementServer` [string]: If role permits, existing management server to connect to
- `ManagementServicePort` [UInt16]: If role permits, port of existing management server
- `SqlServerInstance` [string]: Name of SQL server (instance)
- `WebConsoleUseSSL` [bool]: If Web Console is used, indicates if SSL should be used.
- `WebSiteName` [string]: If Web Console is used, name of the web site
- `WebConsoleAuthorizationMode` [string]: If Web Console is used, authorization mode for the web site
- `SRSInstance` [string]: SQL Server Reporting Services instance if Report Server is used.
- `UseMicrosoftUpdate` [bool]: Indicates that Setup should use Microsoft Update
- `ManagementGroupName` [string]: Name of the management group, required if management servers are deployed
- `DataReader` [PSCredential]: DataReader credential for SqlServerInstance
- `DataWriter` [PSCredential]: DataWriter credential for SqlServerInstance
- `DatabaseName` [string]: Name of Database to use
- `ActionAccount` [PSCredential]: Credential for Action Account
- `DASAccount` [PSCredential]: Credential for DAS Account
- `Ensure` [string]: Possible Values: (Absent,Present) Use Ensure to configure or unconfigure a setting.
- `InstallLocation` [string]: Installation directory
- `DwSqlServerInstance` [string]:  Name of DW SQL server (instance)
- `DwDatabaseName` [string]: Name of DW database
- `DwSqlInstancePort` [UInt16]: Port of DW SQL server (instance)

### ScomDatabaseGroomingSetting

Configure settings for database cleanup.

#### Parameters:
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `PerformanceDataDaysToKeep` [Byte]: How long is performance data kept
- `MonitoringJobDaysToKeep` [Byte]: How long are monitoring jobs kept
- `PerformanceSignatureDaysToKeep` [Byte]: How long are performance signatures kept
- `StateChangeEventDaysToKeep` [Byte]: How long are state change events kept
- `MaintenanceModeHistoryDaysToKeep` [Byte]: How long will the maintenance mode history be available
- `AvailabilityHistoryDaysToKeep` [Byte]: How long will the availability history be available
- `AlertDaysToKeep` [Byte]: How long should alerts be kept
- `JobStatusDaysToKeep` [Byte]: How long should job statuus be kept
- `EventDaysToKeep` [Byte]: How long should events be kept

### ScomDataWarehouseSetting

Data Warehouse configuration for a management server instance

#### Parameters:
- `ServerName` [string] ***Mandatory***: SQL Server/Instance
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `DatabaseName` [string] ***Mandatory***: DW Database

### ScomDiscovery

Configure discovery of an unsealed management pack, either using the `ClassName` parameter for an object class,
or the `GroupOrInstance` to specify groups and class instances.

`Discovery`, `ManagementPack`, `ClassName` are searched for in both `DisplayName` and `Name`. `GroupOrInstance` is only searched
for by `Name`.

#### Parameters:
- `ManagementPack` [string] ***Mandatory***: DisplayName or Name of management pack to discover.
- `Discovery` [string] ***Mandatory***: DisplayName or Name of Discovery
- `Ensure` [string]: Possible Values: (Absent,Present) Use Ensure to configure or unconfigure a setting.
- `GroupOrInstance` [string[]]: List of group/instance names
- `ClassName` [string[]]: DisplayName or Name of object class, if GroupOrInstance is not used.
- `Enforce` [bool]: Indicates if discovery will be enforced.

### ScomErrorReportingSetting

Error Reporting configuration

#### Parameters:
- `ReportSetting` [string] ***Mandatory***: Possible Values: (AutomaticallySend,OptOut,PromptBeforeSending) How should errors be sent?
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.

### ScomHeartbeatSetting

Agent hearbeat setting

#### Parameters:
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `MissingHeartbeatThreshold` [Int32]: Specifies an integer threshold. A management server ignores this many missing heartbeats before it raises an alert.
- `HeartbeatIntervalSeconds` [Int32]: Heartbeat interval.

### ScomMaintenanceSchedule

Configure a maintenance schedule for one or more objects.

#### Parameters:
- `MonitoringObjectGuid` [string[]] ***Mandatory***: List of object GUIDs to configure maintenance schedule for
- `Name` [string] ***Mandatory***: Name of maintenance schedule
- `ReasonCode` [string] ***Mandatory***: Possible Values: (ApplicationInstallation,ApplicationUnresponsive,ApplicationUnstable,LossOfNetworkConnectivity,PlannedApplicationMaintenance,PlannedHardwareInstallation,PlannedHardwareMaintenance,PlannedOperatingSystemReconfiguration,PlannedOther,SecurityIssue,UnplannedApplicationMaintenance,UnplannedHardwareInstallation,UnplannedHardwareMaintenance,UnplannedOperatingSystemReconfiguration,UnplannedOther) Reason for maintenance
- `ActiveStartTime` [DateTime] ***Mandatory***: Start time for maintenance
- `Duration` [UInt32] ***Mandatory***: Duration of maintenance
- `FreqType` [UInt32] ***Mandatory***: <TEXT>
- `FreqRelativeInterval` [UInt32]: <TEXT>
- `FreqRecurrenceFactor` [UInt32]: <TEXT>
- `Recursive` [bool]: <TEXT>
- `FreqInterval` [UInt32]: <TEXT>
- `Comments` [string]: <TEXT>
- `ActiveEndDate` [DateTime]: End time for maintenance
- `Ensure` [string]: Possible Values: (Absent,Present) Use Ensure to configure or unconfigure a setting.

### ScomManagementPack

This resource allows you to import management packs either from file or from a string.

#### Parameters:
- `Name` [string] ***Mandatory***: Name of the management pack
- `ManagementPackPath` [string]: Path to the management pack file to import.
- `ManagementPackContent` [string]: Content of the management pack
- `Ensure` [string]: Possible Values: (Absent,Present) Use Ensure to configure or unconfigure a setting.

### ScomReportingSetting

Reporting Services configuration.

#### Parameters:
- `ReportingServerUrl` [string] ***Mandatory***: Report Server URL to use.
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.


### ScomWebAddressSetting

Web Console setting.

#### Parameters:
- `IsSingleInstance` [string] ***Mandatory***: Possible Values: (yes) Indicates that this resource is used only once in a node configuration.
- `WebConsoleUrl` [string]: Web Console URL
- `OnlineProductKnowledgeUrl` [string]: Knowledge URL
