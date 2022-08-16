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
        [Parameter(Mandatory)]
        [string] 
        $DatabaseName,
        [Parameter(Mandatory)]
        [string]
        $ServerName
    )

    $reasonList = @()
    $setting = Get-ScomDataWarehouseSetting

    if ($setting.DataWarehouseServerName -ne $ServerName)
    {
        $reasonList += @{
            Code   = 'ScomDataWarehouseSetting:ScomDataWarehouseSetting:WrongServerName'
            Phrase = "Approval setting is $($setting.DataWarehouseServerName) but should be $ServerName"
        }
    }

    if ($setting.DataWarehouseDatabaseName -ne $DatabaseName)
    {
        $reasonList += @{
            Code   = 'ScomDataWarehouseSetting:ScomDataWarehouseSetting:WrongDatabaseName'
            Phrase = "Approval setting is $($setting.DataWarehouseDatabaseName) but should be $DatabaseName"
        }
    }

    return @{
        IsSingleInstance = $IsSingleInstance
        DatabaseName     = $setting.DataWarehouseDatabaseName
        ServerName       = $setting.DataWarehouseServerName
        Reasons          = $reasonList
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
        [Parameter(Mandatory)]
        [string] 
        $DatabaseName,
        [Parameter(Mandatory)]
        [string]
        $ServerName
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
        [Parameter(Mandatory)]
        [string] 
        $DatabaseName,
        [Parameter(Mandatory)]
        [string]
        $ServerName
    )

    $parameters = @{
        ErrorAction  = 'Stop'
        DatabaseName = $DatabaseName
        ServerName   = $ServerName
    }

    Set-ScomDataWarehouseSetting @parameters
}

[DscResource()]
class ScomDataWarehouseSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty(Mandatory)] [string] $DatabaseName
    [DscProperty(Mandatory)] [string] $ServerName
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomDataWarehouseSetting] Get()
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
        foreach ($property in [ScomDataWarehouseSetting].GetProperties().Name)
        {
            # Checks if "NotConfigurable" attribute is set
            $notConfigurable = [ScomDataWarehouseSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.DscPropertyAttribute] }).NotConfigurable
            if (!$notConfigurable)
            {
                $value = $this.$property
                # Gets the list of valid values from the ValidateSet attribute
                $validateSet = [ScomDataWarehouseSetting].GetProperty($property).GetCustomAttributes($false).Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
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