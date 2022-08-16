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
        $AlertAutoResolveDays,
        [int]
        $HealthyAlertAutoResolveDays
    )

    $reasonList = @()
    $setting = Get-ScomAlertResolutionSetting

    if ($AlertAutoResolveDays -gt 0 -and $setting.AlertAutoResolveDays -ne $AlertAutoResolveDays)
    {
        $reasonList += @{
            Code   = 'ScomAlertResolutionSetting:ScomAlertResolutionSetting:WrongAutoResolveSetting'
            Phrase = "Auto resolve setting is $($setting.AlertAutoResolveDays) but should be $AlertAutoResolveDays"
        }
    }

    if ($AlertAutoResolveDays -gt 0 -and $setting.AlertAutoResolveDays -ne $AlertAutoResolveDays)
    {
        $reasonList += @{
            Code   = 'ScomAlertResolutionSetting:ScomAlertResolutionSetting:WrongHealthyAutoResolveSetting'
            Phrase = "Healthy auto resolve setting is $($setting.HealthyAlertAutoResolveDays) but should be $HealthyAlertAutoResolveDays"
        }
    }

    return @{
        IsSingleInstance            = $IsSingleInstance
        AlertAutoResolveDays        = $setting.AlertAutoResolveDays
        HealthyAlertAutoResolveDays = $setting.HealthyAlertAutoResolveDays
        Reasons                     = $reasonList
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
        $AlertAutoResolveDays,
        [int]
        $HealthyAlertAutoResolveDays
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
        $AlertAutoResolveDays,
        [int]
        $HealthyAlertAutoResolveDays
    )

    $parameters = @{
        ErrorAction = 'Stop'
    }

    if ($AlertAutoResolveDays -le 0 -and $HealthyAlertAutoResolveDays -le 0)
    {
        return
    }

    if ($AlertAutoResolveDays -gt 0)
    {
        $parameters['AlertAutoResolveDays'] = $AlertAutoResolveDays
    }

    if ($HealthyAlertAutoResolveDays -gt 0)
    {
        $parameters['HealthyAlertAutoResolveDays'] = $HealthyAlertAutoResolveDays
    }

    Set-ScomAlertResolutionSetting @parameters
}

[DscResource()]
class ScomAlertResolutionSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [int] $AlertAutoResolveDays
    [DscProperty()] [int] $HealthyAlertAutoResolveDays
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomAlertResolutionSetting] Get()
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