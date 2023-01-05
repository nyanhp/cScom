[DscResource()]
class ScomAlertResolutionSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [int] $AlertAutoResolveDays
    [DscProperty()] [int] $HealthyAlertAutoResolveDays
    [DscProperty(NotConfigurable)] [ScomReason[]] $Reasons

    [ScomAlertResolutionSetting] Get()
    {
        $reasonList = @()
        $setting = Get-ScomAlertResolutionSetting

        if ($this.AlertAutoResolveDays -gt 0 -and $setting.AlertAutoResolveDays -ne $this.AlertAutoResolveDays)
        {
            $reasonList += @{
                Code   = 'ScomAlertResolutionSetting:ScomAlertResolutionSetting:WrongAutoResolveSetting'
                Phrase = "Auto resolve setting is $($setting.AlertAutoResolveDays) but should be $($this.AlertAutoResolveDays)"
            }
        }

        if ($this.HealthyAlertAutoResolveDays -gt 0 -and $setting.HealthyAlertAutoResolveDays -ne $this.HealthyAlertAutoResolveDays)
        {
            $reasonList += @{
                Code   = 'ScomAlertResolutionSetting:ScomAlertResolutionSetting:WrongHealthyAutoResolveSetting'
                Phrase = "Healthy auto resolve setting is $($setting.HealthyAlertAutoResolveDays) but should be $($this.HealthyAlertAutoResolveDays)"
            }
        }

        return @{
            IsSingleInstance            = $this.IsSingleInstance
            AlertAutoResolveDays        = $setting.AlertAutoResolveDays
            HealthyAlertAutoResolveDays = $setting.HealthyAlertAutoResolveDays
            Reasons                     = $reasonList
        }      
    }

    [void] Set()
    {
        $parameters = @{
            ErrorAction = 'Stop'
        }
    
        if ($this.AlertAutoResolveDays -le 0 -and $this.HealthyAlertAutoResolveDays -le 0)
        {
            return
        }
    
        if ($this.AlertAutoResolveDays -gt 0)
        {
            $parameters['AlertAutoResolveDays'] = $this.AlertAutoResolveDays
        }
    
        if ($this.HealthyAlertAutoResolveDays -gt 0)
        {
            $parameters['HealthyAlertAutoResolveDays'] = $this.HealthyAlertAutoResolveDays
        }
    
        Set-ScomAlertResolutionSetting @parameters     
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
        foreach ($property in [ScomAlertResolutionSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomAlertResolutionSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomAlertResolutionSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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