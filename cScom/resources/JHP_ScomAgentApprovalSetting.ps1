[DscResource()]
class ScomAgentApprovalSetting : ResourceBase
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty(Mandatory)] [ScomApprovalType] $ApprovalType
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomAgentApprovalSetting] Get()
    {
        $reasonList = @()
        $setting = (Get-ScomAgentApprovalSetting).AgentApprovalSetting

        if ($setting -ne $this.ApprovalType)
        {
            $reasonList += @{
                Code   = 'ScomAgentApprovalSetting:ScomAgentApprovalSetting:WrongApprovalSetting'
                Phrase = "Approval setting is $setting but should be $($this.ApprovalType)"
            }
        }

        return @{
            IsSingleInstance = $this.IsSingleInstance
            ApprovalType     = $setting
            Reasons          = $reasonList
        }    
    }

    [void] Set()
    {
        $parameters = @{
            ErrorAction   = 'Stop'
            $this.ApprovalType = $true
            Confirm       = $false
        }
    
        Set-ScomAgentApprovalSetting @parameters      
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
        foreach ($property in [ScomAgentApprovalSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomAgentApprovalSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomAgentApprovalSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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