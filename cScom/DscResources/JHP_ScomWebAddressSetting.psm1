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
        [Parameter(Mandatory)]
        [ValidateSet('yes')]
        [System.String]
        $IsSingleInstance,
        [string]
        $WebConsoleUrl,
        [string]
        $OnlineProductKnowledgeUrl
    )

    $reasonList = @()
    $setting = Get-ScomWebAddressSetting

    if (-not [string]::IsNullOrWhiteSpace($WebConsoleUrl) -and $setting.WebConsoleUrl -ne $WebConsoleUrl)
    {
        $reasonList += @{
            Code   = 'ScomWebAddressSetting:ScomWebAddressSetting:WrongWebUrlSetting'
            Phrase = "Web Console Url is $($setting.WebConsoleUrl) but should be $WebConsoleUrl"
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($OnlineProductKnowledgeUrl) -and $setting.OnlineProductKnowledgeUrl -ne $OnlineProductKnowledgeUrl)
    {
        $reasonList += @{
            Code   = 'ScomWebAddressSetting:ScomWebAddressSetting:WrongKnowledgeUrletting'
            Phrase = "Online Product Knowledge Url is $($setting.OnlineProductKnowledgeUrl) but should be $OnlineProductKnowledgeUrl"
        }
    }

    return @{
        IsSingleInstance          = $IsSingleInstance
        WebConsoleUrl             = $setting.WebConsoleUrl 
        OnlineProductKnowledgeUrl = $setting.OnlineProductKnowledgeUrl 
        Reasons                   = $reasonList
    }
}

function Test-Resource
{
    [OutputType([bool])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('yes')]
        [System.String]
        $IsSingleInstance,
        [string]
        $WebConsoleUrl,
        [string]
        $OnlineProductKnowledgeUrl
    )
    
    return ($(Get-Resource @PSBoundParameters).Reasons.Count -eq 0)
}

function Set-Resource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateSet('yes')]
        [System.String]
        $IsSingleInstance,
        [string]
        $WebConsoleUrl,
        [string]
        $OnlineProductKnowledgeUrl
    )

    $parameters = @{
        ErrorAction = 'Stop'
        Confirm     = $false
    }

    if ($PSBoundParameters.Contains('WebConsoleUrl')) { $parameters['WebConsoleUrl'] = $WebConsoleUrl }
    if ($PSBoundParameters.Contains('OnlineProductKnowledgeUrl')) { $parameters['OnlineProductKnowledgeUrl'] = $OnlineProductKnowledgeUrl }

    Set-ScomWebAddressSetting @parameters
}

[DscResource()]
class ScomWebAddressSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty()] [string] $WebConsoleUrl
    [DscProperty()] [string] $OnlineProductKnowledgeUrl
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomWebAddressSetting] Get()
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