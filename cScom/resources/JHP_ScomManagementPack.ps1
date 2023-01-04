[DscResource()]
class ScomManagementPack : ResourceBase
{
    [DscProperty(Key)] [System.String] $Name
    [DscProperty()] [System.String] $ManagementPackPath
    [DscProperty()] [System.String] $ManagementPackContent
    [DscProperty()] [Ensure] $Ensure
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    ScomManagementPack ()
    {
        $this.Ensure = 'Present'
    }

    [ScomManagementPack] Get()
    {
        $reasonList = @()
        $mp = Get-SCManagementPack -Name $this.Name
    
        if ($null -eq $mp -and $this.Ensure -eq 'Present')
        {
            $reasonList += @{
                Code   = 'ScomManagementPack:ScomManagementPack:ManagementPackNotFound'
                Phrase = "No management pack with the name $($this.Name) was found."
            }
        }
    
        if ($null -ne $mp -and $this.Ensure -eq 'Absent')
        {
            $reasonList += @{
                Code   = 'ScomManagementPack:ScomManagementPack:TooManyManagementPacks'
                Phrase = "A management pack with the name $($this.Name) was found but ensure is set to absent."
            }
        }
    
        return @{
            Name                  = $mp.Name
            ManagementPackPath    = $this.ManagementPackPath
            ManagementPackContent = $this.ManagementPackContent
            Ensure                = $this.Ensure
            Reasons               = $reasonList
        }       
    }

    [void] Set()
    {
        if ($this.Ensure -eq 'Absent')
        {
            Get-SCManagementPack -Name $this.Name | Remove-SCManagementPack
            return
        }
    
        if ($this.ManagementPackContent -and $this.ManagementPackPath)
        {
            throw ([ArgumentException]::new('You cannot use ManagementPackContent and ManagementPackPath at the same time.'))
        }
    
        if ($this.ManagementPackPath -and -not (Test-Path -Path $this.ManagementPackPath))
        {
            throw ([IO.FileNotFoundException]::new("$($this.ManagementPackPath) was not found."))
        }
    
        if ((Get-Item -Path $this.ManagementPackPath).Extension -notin '.xml', '.mp', '.mpb')
        {
            throw ([ArgumentException]::new("Invalid management pack extension. '$((Get-Item -Path $this.ManagementPackPath).Extension)' not in .xml,.mp,.mpb"))
        }
    
        if ($this.ManagementPackContent)
        {
            $tmpPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($this.Name).xml"
            $this.ManagementPackPath = (New-Item -ItemType File -Path $tmpPath -Force).FullName
            Set-Content -Path $tmpPath -Force -Encoding Unicode -Value $this.ManagementPackContent
        }
    
        if ($this.ManagementPackPath)
        {
            Import-SCManagementPack -FullName $this.ManagementPackPath
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
        foreach ($property in [ScomManagementPack].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomManagementPack].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomManagementPack].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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