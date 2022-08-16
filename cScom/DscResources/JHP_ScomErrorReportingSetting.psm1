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

enum ReportSetting
{
    AutomaticallySend
    OptOut # Parameter name DoNotSend, whoever thought of this brilliant idea.
    PromptBeforeSending
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
        [ReportSetting]
        $ReportSetting
    )

    $reasonList = @()
    $setting = (Get-ScomErrorReportingSetting).ErrorReportingSetting

    if ($setting -ne $ReportSetting)
    {
        $reasonList += @{
            Code   = 'ScomErrorReportingSetting:ScomErrorReportingSetting:WrongApprovalSetting'
            Phrase = "Approval setting is $setting but should be $ReportSetting"
        }
    }

    return @{
        IsSingleInstance = $IsSingleInstance
        ReportSetting    = $setting
        Reasons          = $reasonList
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
        [ReportSetting]
        $ReportSetting
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
        [ReportSetting]
        $ReportSetting
    )

    $parameters = @{
        ErrorAction    = 'Stop'
        $ReportSetting = $true
        Confirm        = $false
    }

    if ($parameters.Contains('OptOut'))
    {
        $parameters.Remove('OptOut')
        $parameters['DoNotSend'] = $true
    }

    Set-ScomErrorReportingSetting @parameters
}

[DscResource()]
class ScomErrorReportingSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty(Mandatory)] [ReportSetting] $ReportSetting
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomErrorReportingSetting] Get()
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
        foreach ($property in [ScomErrorReportingSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomErrorReportingSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomErrorReportingSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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