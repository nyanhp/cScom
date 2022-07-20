<#
$MP = Get-SCOMManagementPack -DisplayName "My SQL MP Customization" | Where-Object {$_.Sealed -eq $False}
$Class = Get-SCOMClass -DisplayName "SQL DB Engine"
$Discovery = Get-SCOMDiscovery -DisplayName *rule*
Enable-SCOMDiscovery -Class $Class -ManagementPack $MP -Discovery $Discovery -Enforce
#>
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
    [OutputType([hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Discovery,

        [Parameter(Mandatory)]
        [string]
        $ManagementPack,

        [Parameter()]
        [string[]]
        $Class,

        [Parameter()]
        [string[]]
        $GroupOrInstance,

        [Parameter()]
        [bool]
        $Enforce,

        [Ensure]
        $Ensure
    )

    $manPack = Get-SCOMManagementPack | Where-Object { -not $_.Sealed -and ($_.DisplayName -eq $ManagementPack -or $_.Name -eq $ManagementPack) }
    $disco = Get-SCDiscovery | Where-Object { $_.DisplayName -eq $Discovery -or $_.Name -eq $Discovery }

    $reasonList = @()

    if ($Ensure -eq 'Present' -and -not $manPack)
    {
        $reasonList += @{
            Code   = 'ScomDiscovery:ScomDiscovery:NoManagementPack'
            Phrase = "No management pack called $($ManagementPack) found. Is it maybe sealed?"
        }
    }

    if ($Ensure -eq 'Present' -and -not $disco)
    {
        $reasonList += @{
            Code   = 'ScomDiscovery:ScomDiscovery:NoDiscovery'
            Phrase = "No discovery called $($Discovery) found."
        }
    }
   
    if ($Ensure -eq 'Absent' -and $disco.Enabled)
    {
        $reasonList += @{
            Code   = 'ScomDiscovery:ScomDiscovery:DiscoveryConfigured'
            Phrase = "Discovery $($Name) is enabled, should be disabled. Discovery ID $($disco.Id)"
        }
    }
   
    if ($Ensure -eq 'Present' -and -not $disco.Enabled)
    {
        $reasonList += @{
            Code   = 'ScomDiscovery:ScomDiscovery:DiscoveryNotConfigured'
            Phrase = "Discovery $($Name) is disabled, should be enabled."
        }
    }

   
    return @{
        Discovery       = $disco.Name
        ManagementPack  = $manPack.Name
        Class           = $Class
        GroupOrInstance = $GroupOrInstance
        Enforce         = $Enforce
        Reasons         = $reasonList
    }
}

function Set-Resource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Discovery,

        [Parameter(Mandatory)]
        [string]
        $ManagementPack,

        [Parameter()]
        [string[]]
        $Class,

        [Parameter()]
        [string[]]
        $GroupOrInstance,

        [Parameter()]
        [bool]
        $Enforce,

        [Ensure]
        $Ensure
    )

    $manPack = Get-SCOMManagementPack | Where-Object { -not $_.Sealed -and ($_.DisplayName -eq $ManagementPack -or $_.Name -eq $ManagementPack) }
    $disco = Get-SCDiscovery | Where-Object { $_.DisplayName -eq $Discovery -or $_.Name -eq $Discovery }

    if (-not $manPack)
    {
        Write-Error -Message "No management pack called $($ManagementPack) found. Is it maybe sealed?"
        return
    }

    if (-not $disco)
    {
        Write-Error -Message "No discovery called $($Discovery) found."
        return
    }

    $parameters = @{
        ManagementPack = $manPack
        Discovery      = $disco
        Enforce        = $Enforce
    }
    
    if ($Class)
    {
        $scomClass = Get-SCOMClass | Where-Object { $_.DisplayName -in $Class -or $_.Name -in $Class }
        if (-not $scomClass) { Write-Error -Message "No class(es) called $($Class) found."; return }

        $parameters['Class'] = $scomClass
    }
    elseif ($GroupOrInstance)
    {
        $scomInstance = Get-SCOMClassInstance | Where-Object DisplayName -in $GroupOrInstance
        if (-not $scomInstance) { Write-Error -Message "No class instance(s) or group(s) called $($GroupOrInstance) found."; return }

        $parameters['Instance'] = $Class
    }

    if ($Ensure -eq 'Present')
    {
        Enable-SCOMDiscovery @parameters
    }

    if ($Ensure -eq 'Absent')
    {
        Disable-SCOMDiscovery @parameters
    }
}

function Test-Resource
{
    [OutputType([bool])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]
        $Discovery,

        [Parameter(Mandatory)]
        [string]
        $ManagementPack,

        [Parameter()]
        [string[]]
        $Class,

        [Parameter()]
        [string[]]
        $GroupOrInstance,

        [Parameter()]
        [bool]
        $Enforce,

        [Ensure]
        $Ensure
    )
    
    $currentStatus = Get-Resource @PSBoundParameters
    $currentStatus.Reasons.Count -eq 0
}
      
[DscResource()]
class ScomDiscovery
{
    [DscProperty(Key)] [string] $Discovery
    [DscProperty(Key)] [string] $ManagementPack
    [DscProperty()] [string[]] $Class
    [DscProperty()] [string[]] $GroupOrInstance
    [DscProperty()] [bool] $Enforce
    [DscProperty()] [Ensure] $Ensure
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons
   
    ScomDiscovery ()
    {
        $this.Ensure = 'Present'
        $this.Enforce = $true
    }

    [ScomDiscovery] Get()
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
        foreach ($property in [ScomDiscovery].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomDiscovery].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomDiscovery].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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