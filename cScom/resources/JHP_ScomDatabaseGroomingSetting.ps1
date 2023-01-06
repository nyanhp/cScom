[DscResource()]
class ScomDatabaseGroomingSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [byte] $AlertDaysToKeep
    [DscProperty()] [byte] $AvailabilityHistoryDaysToKeep
    [DscProperty()] [byte] $EventDaysToKeep
    [DscProperty()] [byte] $JobStatusDaysToKeep
    [DscProperty()] [byte] $MaintenanceModeHistoryDaysToKeep
    [DscProperty()] [byte] $MonitoringJobDaysToKeep
    [DscProperty()] [byte] $PerformanceDataDaysToKeep
    [DscProperty()] [byte] $PerformanceSignatureDaysToKeep
    [DscProperty()] [byte] $StateChangeEventDaysToKeep
    [DscProperty(NotConfigurable)] [ScomReason[]] $Reasons

    [ScomDatabaseGroomingSetting] Get()
    {
        $reasonList = @()
        $setting = Get-ScomDatabaseGroomingSetting
    
        foreach ($parameter in $this.GetConfigurableDscProperties().GetEnumerator())
        {
            if ($parameter.Key -notlike '*Keep') { continue }
            $settingName = $parameter.Key
            
            if ($setting.$settingName -ne $parameter.value)
            {
                $reasonList += @{
                    Code   = "ScomDatabaseGroomingSetting:ScomDatabaseGroomingSetting:Wrong$($settingName)Setting"
                    Phrase = "Setting '$settingName' is $($setting.$settingName) but should be $($parameter.value)"
                }
            }
        }
    
        return @{
            IsSingleInstance                 = $this.IsSingleInstance
            AlertDaysToKeep                  = $setting.AlertDaysToKeep
            AvailabilityHistoryDaysToKeep    = $setting.AvailabilityHistoryDaysToKeep
            EventDaysToKeep                  = $setting.EventDaysToKeep
            JobStatusDaysToKeep              = $setting.JobStatusDaysToKeep
            MaintenanceModeHistoryDaysToKeep = $setting.MaintenanceModeHistoryDaysToKeep
            MonitoringJobDaysToKeep          = $setting.MonitoringJobDaysToKeep
            PerformanceDataDaysToKeep        = $setting.PerformanceDataDaysToKeep
            PerformanceSignatureDaysToKeep   = $setting.PerformanceSignatureDaysToKeep
            StateChangeEventDaysToKeep       = $setting.StateChangeEventDaysToKeep
            Reasons                          = $reasonList
        }      
    }

    [void] Set()
    {
        $parameters = $this.GetConfigurableDscProperties()
    
        Set-ScomDatabaseGroomingSetting @parameters  
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
        foreach ($property in [ScomDatabaseGroomingSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomDatabaseGroomingSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomDatabaseGroomingSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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