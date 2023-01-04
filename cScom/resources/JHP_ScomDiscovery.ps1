[DscResource()]
class ScomDiscovery : ResourceBase
{
    [DscProperty(Key)] [string] $Discovery
    [DscProperty(Key)] [string] $ManagementPack
    [DscProperty()] [string[]] $ClassName
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
        $manPack = Get-ScomManagementPack | Where-Object { -not $_.Sealed -and ($_.DisplayName -eq $this.ManagementPack -or $_.Name -eq $this.ManagementPack) }
        $disco = Get-SCDiscovery | Where-Object { $_.DisplayName -eq $this.Discovery -or $_.Name -eq $this.Discovery }
    
        $reasonList = @()
    
        if ($this.Ensure -eq 'Present' -and -not $manPack)
        {
            $reasonList += @{
                Code   = 'ScomDiscovery:ScomDiscovery:NoManagementPack'
                Phrase = "No management pack called $($this.ManagementPack) found. Is it maybe sealed?"
            }
        }
    
        if ($this.Ensure -eq 'Present' -and -not $disco)
        {
            $reasonList += @{
                Code   = 'ScomDiscovery:ScomDiscovery:NoDiscovery'
                Phrase = "No discovery called $($this.Discovery) found."
            }
        }
       
        if ($this.Ensure -eq 'Absent' -and $disco.Enabled)
        {
            $reasonList += @{
                Code   = 'ScomDiscovery:ScomDiscovery:DiscoveryConfigured'
                Phrase = "Discovery $($this.Name) is enabled, should be disabled. Discovery ID $($disco.Id)"
            }
        }
       
        if ($this.Ensure -eq 'Present' -and -not $disco.Enabled)
        {
            $reasonList += @{
                Code   = 'ScomDiscovery:ScomDiscovery:DiscoveryNotConfigured'
                Phrase = "Discovery $($this.Name) is disabled, should be enabled."
            }
        }
    
       
        return @{
            Discovery       = $disco.Name
            ManagementPack  = $manPack.Name
            Class           = $this.ClassName
            GroupOrInstance = $this.GroupOrInstance
            Enforce         = $this.Enforce
            Reasons         = $reasonList
        }      
    }

    [void] Set()
    {
        $manPack = Get-ScomManagementPack | Where-Object { -not $_.Sealed -and ($_.DisplayName -eq $this.ManagementPack -or $_.Name -eq $this.ManagementPack) }
        $disco = Get-SCDiscovery | Where-Object { $_.DisplayName -eq $this.Discovery -or $_.Name -eq $this.Discovery }
    
        if (-not $manPack)
        {
            Write-Error -Message "No management pack called $($this.ManagementPack) found. Is it maybe sealed?"
            return
        }
    
        if (-not $disco)
        {
            Write-Error -Message "No discovery called $($this.Discovery) found."
            return
        }
    
        $parameters = @{
            ManagementPack = $manPack
            Discovery      = $disco
            Enforce        = $this.Enforce
        }
        
        if ($this.ClassName)
        {
            $scomClass = Get-ScomClass | Where-Object { $_.DisplayName -in $this.ClassName -or $_.Name -in $this.ClassName }
            if (-not $scomClass) { Write-Error -Message "No class(es) called $($this.ClassName) found."; return }
    
            $parameters['Class'] = $scomClass
        }
        elseif ($this.GroupOrInstance)
        {
            $scomInstance = Get-ScomClassInstance | Where-Object DisplayName -in $this.GroupOrInstance
            if (-not $scomInstance) { Write-Error -Message "No class instance(s) or group(s) called $($this.GroupOrInstance) found."; return }
    
            $parameters['Instance'] = $this.ClassName
        }
    
        if ($this.Ensure -eq 'Present')
        {
            Enable-ScomDiscovery @parameters
        }
    
        if ($this.Ensure -eq 'Absent')
        {
            Disable-ScomDiscovery @parameters
        }     
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