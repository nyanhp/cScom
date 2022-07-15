<#New-SCOMMaintenanceSchedule
   [-Name] <String>
   [-Recursive]
   [-Enabled]
   [-MonitoringObjects] <Guid[]>
   [-ActiveStartTime] <DateTime>
   [[-ActiveEndDate] <DateTime>]
   [-Duration] <Int32>
   [-ReasonCode] <MaintenanceModeReason>
   [[-Comments] <String>]
   [-FreqType] <Int32>
   [[-FreqInterval] <Int32>]
   [[-FreqRecurrenceFactor] <Int32>]
   [[-FreqRelativeInterval] <Int32>] #>
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
   
[DscResource()]
class ScomMaintenanceSchedule
{
    [DscProperty(Key)] [string] $Name
    [DscProperty(Mandatory)] [guid[]] $MonitoringObject
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
        $schedule = Get-SCOMMaintenanceScheduleList | Where-Object -Property Name -eq $this.Name | Get-SCOMMaintenanceSchedule
        $reasonList = @()

        if ($this.Ensure -eq 'Absent' -and $null -ne $schedule)
        {
            $reasonList += @{
                Code   = 'ScomMaintenanceSchedule:ScomMaintenanceSchedule:SchedulePresent'
                Phrase = "Maintenance schedule $($this.Name) is present, should be absent. Schedule ID $($schedule.Id)"
            }
        }

        if ($this.Ensure -eq 'Present' -and $null -eq $schedule)
        {
            $reasonList += @{
                Code   = 'ScomMaintenanceSchedule:ScomMaintenanceSchedule:ScheduleAbsent'
                Phrase = "Maintenance schedule $($this.Name) is absent, should be present."
            }
        }

        # Check other properties

        return @{
            Reasons = $reasonList
        }
    }

    [void] Set()
    {
        $schedule = Get-SCOMMaintenanceScheduleList | Where-Object -Property Name -eq $this.Name | Get-SCOMMaintenanceSchedule

        if ($this.Ensure -eq 'Present' -and $schedule)
        {
            $parameters = Sync-Parameter -Parameters $this.GetConfigurableDscProperties() -Command (Get-Command -Name Edit-SCOMMaintenanceSchedule)
            Edit-ScomMaintenanceSchedule @parameters -Id $schedule.Id
        }
        elseif ($this.Ensure -eq 'Present')
        {
            
            $parameters = Sync-Parameter -Parameters $this.GetConfigurableDscProperties() -Command (Get-Command -Name New-SCOMMaintenanceSchedule)
        }
        else
        {
            $schedule | Remove-ScomMaintenanceSchedule -Confirm:$false
        }
    }

    [bool] Test()
    {
        $currentStatus = $this.Get()
        return ($currentStatus.Reasons.Count -eq 0) # Shrug-Emoji :)
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