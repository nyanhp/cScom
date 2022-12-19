
try
{
    [Ensure]
}
catch
{
    enum Ensure
    {
        Present
        Absent
    }
}

try
{
    [Reason]
}
catch
{
    # Support for DSC v3, for what it's worth
    class Reason
    {
        [DscProperty()]
        [string] $Code
  
        [DscProperty()]
        [string] $Phrase
    }
}

try
{
    [Role]
}
catch
{
    enum Role
    {
        FirstManagementServer
        AdditionalManagementServer
        ReportServer
        WebConsole
        NativeConsole
    }
}

try
{
    [MaintenanceModeReason]
}
catch
{
    enum MaintenanceModeReason
    {
        PlannedOther
        UnplannedOther
        PlannedHardwareMaintenance
        UnplannedHardwareMaintenance
        PlannedHardwareInstallation
        UnplannedHardwareInstallation
        PlannedOperatingSystemReconfiguration
        UnplannedOperatingSystemReconfiguration
        PlannedApplicationMaintenance
        UnplannedApplicationMaintenance
        ApplicationInstallation
        ApplicationUnresponsive
        ApplicationUnstable
        SecurityIssue
        LossOfNetworkConnectivity
    }
}

function Get-Resource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string[]]
        $MonitoringObjectGuid,

        [Parameter(Mandatory)]
        [datetime]
        $ActiveStartTime,

        [Parameter(Mandatory)]
        [uint32]
        $Duration,

        [Parameter(Mandatory)]
        [MaintenanceModeReason]
        $ReasonCode,

        [Parameter(Mandatory)]
        [uint32]
        $FreqType,

        [bool]
        $Recursive,

        [Ensure]
        $Ensure,

        [datetime]
        $ActiveEndDate,

        [string]
        $Comments,

        [uint32]
        $FreqInterval,

        [uint32]
        $FreqRecurrenceFactor,

        [uint32]
        $FreqRelativeInterval
    )

    $schedule = Get-ScomMaintenanceScheduleList | Where-Object -Property Name -eq $Name | Get-ScomMaintenanceSchedule
    $reasonList = @()

    if ($Ensure -eq 'Absent' -and $null -ne $schedule)
    {
        $reasonList += @{
            Code   = 'ScomMaintenanceSchedule:ScomMaintenanceSchedule:SchedulePresent'
            Phrase = "Maintenance schedule $($Name) is present, should be absent. Schedule ID $($schedule.Id)"
        }
    }

    if ($Ensure -eq 'Present' -and $null -eq $schedule)
    {
        $reasonList += @{
            Code   = 'ScomMaintenanceSchedule:ScomMaintenanceSchedule:ScheduleAbsent'
            Phrase = "Maintenance schedule $($Name) is absent, should be present."
        }
    }

    # Check other properties

    return @{
        Reasons = $reasonList
    }
}

function Set-Resource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string[]]
        $MonitoringObjectGuid,

        [Parameter(Mandatory)]
        [datetime]
        $ActiveStartTime,

        [Parameter(Mandatory)]
        [uint32]
        $Duration,

        [Parameter(Mandatory)]
        [MaintenanceModeReason]
        $ReasonCode,

        [Parameter(Mandatory)]
        [uint32]
        $FreqType,

        [bool]
        $Recursive,

        [Ensure]
        $Ensure,

        [datetime]
        $ActiveEndDate,

        [string]
        $Comments,

        [uint32]
        $FreqInterval,

        [uint32]
        $FreqRecurrenceFactor,

        [uint32]
        $FreqRelativeInterval
    )
    
    $schedule = Get-ScomMaintenanceScheduleList | Where-Object -Property Name -eq $this.Name | Get-ScomMaintenanceSchedule

    if ($this.Ensure -eq 'Present' -and $schedule)
    {
        $parameters = Sync-Parameter -Parameters $this.GetConfigurableDscProperties() -Command (Get-Command -Name Edit-ScomMaintenanceSchedule)
        Edit-ScomMaintenanceSchedule @parameters -Id $schedule.Id
    }
    elseif ($this.Ensure -eq 'Present')
    {
            
        $parameters = Sync-Parameter -Parameters $this.GetConfigurableDscProperties() -Command (Get-Command -Name New-ScomMaintenanceSchedule)
        New-ScomMaintenanceSchedule @parameters
    }
    else
    {
        $schedule | Remove-ScomMaintenanceSchedule -Confirm:$false
    }
}

function Test-Resource
{
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Name,

        [Parameter(Mandatory)]
        [string[]]
        $MonitoringObjectGuid,

        [Parameter(Mandatory)]
        [datetime]
        $ActiveStartTime,

        [Parameter(Mandatory)]
        [uint32]
        $Duration,

        [Parameter(Mandatory)]
        [MaintenanceModeReason]
        $ReasonCode,

        [Parameter(Mandatory)]
        [uint32]
        $FreqType,

        [bool]
        $Recursive,

        [Ensure]
        $Ensure,

        [datetime]
        $ActiveEndDate,

        [string]
        $Comments,

        [uint32]
        $FreqInterval,

        [uint32]
        $FreqRecurrenceFactor,

        [uint32]
        $FreqRelativeInterval
    )
    
    $currentStatus = Get-Resource @PSBoundParameters
    $currentStatus.Reasons.Count -eq 0
}

[DscResource()]
class ScomMaintenanceSchedule
{
    [DscProperty(Key)] [string] $Name
    [DscProperty(Mandatory)] [string[]] $MonitoringObjectGuid
    [DscProperty(Mandatory)] [datetime] $ActiveStartTime
    [DscProperty(Mandatory)] [uint32] $Duration
    [DscProperty(Mandatory)] [MaintenanceModeReason] $ReasonCode
    [DscProperty(Mandatory)] [uint32] $FreqType
    [DscProperty()] [bool] $Recursive
    [DscProperty()] [Ensure] $Ensure
    [DscProperty()] [datetime] $ActiveEndDate
    [DscProperty()] [string] $Comments
    [DscProperty()] [uint32] $FreqInterval
    [DscProperty()] [uint32] $FreqRecurrenceFactor
    [DscProperty()] [uint32] $FreqRelativeInterval
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    ScomMaintenanceSchedule ()
    {
        $this.Ensure = 'Present'
        $this.Recursive = $false
    }

    [ScomMaintenanceSchedule] Get()
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
        Return (Test-Resource @parameter)
    }

    [Hashtable] GetConfigurableDscProperties()
    {
        # This method returns a hashtable of properties with two special workarounds
        # The hashtable will not include any properties marked as "NotConfigurable"
        # Any properties with a ValidateSet of "True","False" will beconverted to Boolean type
        # The intent is to simplify splatting to functions
        # Source: https://gist.github.com/mgreenegit/e3a9b4e136fc2d510cf87e20390daa44
        $DscProperties = @{}
        foreach ($property in [ScomMaintenanceSchedule].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomMaintenanceSchedule].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomMaintenanceSchedule].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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