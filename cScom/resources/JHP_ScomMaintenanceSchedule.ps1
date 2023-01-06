[DscResource()]
class ScomMaintenanceSchedule
{
    [DscProperty(Key)] [string] $Name
    [DscProperty(Mandatory)] [string[]] $MonitoringObjectGuid
    [DscProperty(Mandatory)] [datetime] $ActiveStartTime
    [DscProperty(Mandatory)] [uint32] $Duration
    [DscProperty(Mandatory)] [ScomMaintenanceModeReason] $ReasonCode
    [DscProperty(Mandatory)] [uint32] $FreqType
    [DscProperty()] [bool] $Recursive
    [DscProperty()] [ScomEnsure] $Ensure
    [DscProperty()] [datetime] $ActiveEndDate
    [DscProperty()] [string] $Comments
    [DscProperty()] [uint32] $FreqInterval
    [DscProperty()] [uint32] $FreqRecurrenceFactor
    [DscProperty()] [uint32] $FreqRelativeInterval
    [DscProperty(NotConfigurable)] [ScomReason[]] $Reasons

    ScomMaintenanceSchedule ()
    {
        $this.Ensure = 'Present'
        $this.Recursive = $false
    }

    [ScomMaintenanceSchedule] Get()
    {
        $schedule = Get-ScomMaintenanceScheduleList | Where-Object -Property Name -eq $this.Name | Get-ScomMaintenanceSchedule
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

    [bool] Test()
    {
        return ($this.Get().Reasons.Count -eq 0)
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