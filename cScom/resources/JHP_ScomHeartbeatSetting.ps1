[DscResource()]
class ScomHeartbeatSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [int] $MissingHeartbeatThreshold
    [DscProperty()] [int] $HeartbeatIntervalSeconds
    [DscProperty(NotConfigurable)] [ScomReason[]] $Reasons

    [ScomHeartbeatSetting] Get()
    {
        $reasonList = @()
        $setting = Get-ScomHeartbeatSetting
    
        if ($this.HeartbeatIntervalSeconds -gt 0 -and $setting.AgentHeartbeatInterval -ne $this.HeartbeatIntervalSeconds)
        {
            $reasonList += @{
                Code   = 'ScomHeartbeatSetting:ScomHeartbeatSetting:WrongHeartbeatIntervalSetting'
                Phrase = "Heartbeat Interval setting is $($setting.AgentHeartbeatInterval) but should be $($this.HeartbeatIntervalSeconds)"
            }
        }
    
        if ($this.MissingHeartbeatThreshold -gt 0 -and $setting.MissingHeartbeatThreshold -ne $this.MissingHeartbeatThreshold)
        {
            $reasonList += @{
                Code   = 'ScomHeartbeatSetting:ScomHeartbeatSetting:WrongThresholdSetting'
                Phrase = "Missing Heartbeat Threshold setting is $($setting.MissingHeartbeatThreshold) but should be $this.MissingHeartbeatThreshold"
            }
        }
    
        return @{
            IsSingleInstance          = $this.IsSingleInstance
            MissingHeartbeatThreshold = $setting.MissingHeartbeatThreshold
            HeartbeatIntervalSeconds  = $setting.AgentHeartbeatInterval
            Reasons                   = $reasonList
        }      
    }

    [void] Set()
    {
        $parameters = @{
            ErrorAction = 'Stop'
            Confirm     = $false
        }
    
        if ($this.MissingHeartbeatThreshold -gt 0) { $parameters['MissingHeartbeatThreshold'] = $this.MissingHeartbeatThreshold }
        if ($this.HeartbeatIntervalSeconds -gt 0) { $parameters['HeartbeatInterval'] = New-TimeSpan -Seconds $this.HeartbeatInterval }
    
        Set-ScomHeartbeatSetting @parameters
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
        foreach ($property in [ScomHeartbeatSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomHeartbeatSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomHeartbeatSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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