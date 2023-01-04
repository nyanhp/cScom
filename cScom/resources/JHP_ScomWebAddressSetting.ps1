[DscResource()]
class ScomWebAddressSetting : ResourceBase
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [string] $WebConsoleUrl
    [DscProperty()] [string] $OnlineProductKnowledgeUrl
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomWebAddressSetting] Get()
    {
        $reasonList = @()
        $setting = Get-ScomWebAddressSetting
    
        if (-not [string]::IsNullOrWhiteSpace($this.WebConsoleUrl) -and $setting.WebConsoleUrl -ne $this.WebConsoleUrl)
        {
            $reasonList += @{
                Code   = 'ScomWebAddressSetting:ScomWebAddressSetting:WrongWebUrlSetting'
                Phrase = "Web Console Url is $($setting.WebConsoleUrl) but should be $this.WebConsoleUrl"
            }
        }
    
        if (-not [string]::IsNullOrWhiteSpace($this.OnlineProductKnowledgeUrl) -and $setting.OnlineProductKnowledgeUrl -ne $this.OnlineProductKnowledgeUrl)
        {
            $reasonList += @{
                Code   = 'ScomWebAddressSetting:ScomWebAddressSetting:WrongKnowledgeUrletting'
                Phrase = "Online Product Knowledge Url is $($setting.OnlineProductKnowledgeUrl) but should be $this.OnlineProductKnowledgeUrl"
            }
        }
    
        return @{
            IsSingleInstance          = $this.IsSingleInstance
            WebConsoleUrl             = $setting.WebConsoleUrl 
            OnlineProductKnowledgeUrl = $setting.OnlineProductKnowledgeUrl 
            Reasons                   = $reasonList
        }  
    }

    [void] Set()
    {

        $parameters = @{
            ErrorAction = 'Stop'
            Confirm     = $false
        }
    
        if ($this.WebConsoleUrl) { $parameters['WebConsoleUrl'] = $this.WebConsoleUrl }
        if ($this.OnlineProductKnowledgeUrl) { $parameters['OnlineProductKnowledgeUrl'] = $this.OnlineProductKnowledgeUrl }
    
        Set-ScomWebAddressSetting @parameters 
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
        foreach ($property in [ScomWebAddressSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomWebAddressSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomWebAddressSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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