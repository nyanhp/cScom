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

function Get-Resource
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [System.String]
        $IsSingleInstance,
        [int]
        $MissingHeartbeatThreshold,
        [timespan]
        $HeartbeatInterval
    )

    $reasonList = @()
    $setting = Get-ScomHeartbeatSetting

    if ($setting.AgentHeartbeatInterval -ne $HeartbeatInterval)
    {
        $reasonList += @{
            Code   = 'ScomHeartbeatSetting:ScomHeartbeatSetting:WrongHeartbeatIntervalSetting'
            Phrase = "Heartbeat Interval setting is $($setting.AgentHeartbeatInterval) but should be $HeartbeatInterval"
        }
    }

    if ($setting.MissingHeartbeatThreshold -ne $MissingHeartbeatThreshold)
    {
        $reasonList += @{
            Code   = 'ScomHeartbeatSetting:ScomHeartbeatSetting:WrongThresholdSetting'
            Phrase = "Missing Heartbeat Threshold setting is $($setting.MissingHeartbeatThreshold) but should be $MissingHeartbeatThreshold"
        }
    }

    return @{
        IsSingleInstance          = $IsSingleInstance
        MissingHeartbeatThreshold = $setting.MissingHeartbeatThreshold
        HeartbeatInterval         = $setting.AgentHeartbeatInterval
        Reasons                   = $reasonList
    }
}

function Test-Resource
{
    [OutputType([bool])]
    [CmdletBinding()]
    param
    (
        [System.String]
        $IsSingleInstance,
        [int]
        $MissingHeartbeatThreshold,
        [timespan]
        $HeartbeatInterval
    )
    
    return ($(Get-Resource @PSBoundParameters).Reasons.Count -eq 0)
}

function Set-Resource
{
    [CmdletBinding()]
    param
    (
        [System.String]
        $IsSingleInstance,
        [int]
        $MissingHeartbeatThreshold,
        [timespan]
        $HeartbeatInterval
    )

    $parameters = @{
        ErrorAction = 'Stop'
        Confirm     = $false
    }

    if ($PSBoundParameters.Contains('MissingHeartbeatThreshold')) { $parameters['MissingHeartbeatThreshold'] = $MissingHeartbeatThreshold }
    if ($PSBoundParameters.Contains('HeartbeatInterval')) { $parameters['HeartbeatInterval'] = $HeartbeatInterval }

    Set-ScomHeartbeatSetting @parameters
}

[DscResource()]
class ScomHeartbeatSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [int] $MissingHeartbeatThreshold
    [DscProperty()] [timespan] $HeartbeatInterval
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomHeartbeatSetting] Get()
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
        return (Test-Resource @parameter)
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