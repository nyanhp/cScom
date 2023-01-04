


try
{
    [Role]
}
catch
{
    enum Role
    {
        FirstManagementServer
        AdditionalManagementServer
        ReportServer
        WebConsole
        NativeConsole
    }
}

function Get-Resource
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [System.String]
        $Name,
        [System.String]
        $ManagementPackPath,
        [System.String]
        $ManagementPackContent,
        [Ensure]
        $Ensure
    )

    $reasonList = @()
    $mp = Get-SCManagementPack -Name $Name

    if ($null -eq $mp -and $Ensure -eq 'Present')
    {
        $reasonList += @{
            Code   = 'ScomManagementPack:ScomManagementPack:ManagementPackNotFound'
            Phrase = "No management pack with the name $($Name) was found."
        }
    }

    if ($null -ne $mp -and $Ensure -eq 'Absent')
    {
        $reasonList += @{
            Code   = 'ScomManagementPack:ScomManagementPack:TooManyManagementPacks'
            Phrase = "A management pack with the name $($Name) was found but ensure is set to absent."
        }
    }

    return @{
        Name                  = $mp.Name
        ManagementPackPath    = $ManagementPackPath
        ManagementPackContent = $ManagementPackContent
        Ensure                = $Ensure
        Reasons               = $reasonList
    }
}

function Test-Resource
{
    [OutputType([bool])]
    [CmdletBinding()]
    param
    (
        [System.String]
        $Name,
        [System.String]
        $ManagementPackPath,
        [System.String]
        $ManagementPackContent,
        [Ensure]
        $Ensure
    )
    
    return ($(Get-Resource @PSBoundParameters).Reasons.Count -eq 0)
}

function Set-Resource
{
    [CmdletBinding()]
    param
    (
        [System.String]
        $Name,
        [System.String]
        $ManagementPackPath,
        [System.String]
        $ManagementPackContent,
        [Ensure]
        $Ensure
    )

    if ($Ensure -eq 'Absent')
    {
        Get-SCManagementPack -Name $Name | Remove-SCManagementPack
        return
    }

    if ($ManagementPackContent -and $ManagementPackPath)
    {
        throw ([ArgumentException]::new('You cannot use ManagementPackContent and ManagementPackPath at the same time.'))
    }

    if ($ManagementPackPath -and -not (Test-Path -Path $ManagementPackPath))
    {
        throw ([IO.FileNotFoundException]::new("$($ManagementPackPath) was not found."))
    }

    if ((Get-Item -Path $ManagementPackPath).Extension -notin '.xml', '.mp', '.mpb')
    {
        throw ([ArgumentException]::new("Invalid management pack extension. '$((Get-Item -Path $ManagementPackPath).Extension)' not in .xml,.mp,.mpb"))
    }

    if ($ManagementPackContent)
    {
        $tmpPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($Name).xml"
        $ManagementPackPath = (New-Item -ItemType File -Path $tmpPath -Force).FullName
        Set-Content -Path $tmpPath -Force -Encoding Unicode -Value $ManagementPackContent
    }

    if ($ManagementPackPath)
    {
        Import-SCManagementPack -FullName $ManagementPackPath
    }
}

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