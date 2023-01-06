[DscResource()]
class ScomDataWarehouseSetting
{
    [DscProperty(Key)] [ValidateSet('yes')] [string] $IsSingleInstance
    [DscProperty(Mandatory)] [string] $DatabaseName
    [DscProperty(Mandatory)] [string] $ServerName
    [DscProperty(NotConfigurable)] [ScomReason[]] $Reasons

    [ScomDataWarehouseSetting] Get()
    {

        $reasonList = @()
        $setting = Get-ScomDataWarehouseSetting
    
        if ($setting.DataWarehouseServerName -ne $this.ServerName)
        {
            $reasonList += @{
                Code   = 'ScomDataWarehouseSetting:ScomDataWarehouseSetting:WrongServerName'
                Phrase = "Approval setting is $($setting.DataWarehouseServerName) but should be $($this.ServerName)"
            }
        }
    
        if ($setting.DataWarehouseDatabaseName -ne $this.DatabaseName)
        {
            $reasonList += @{
                Code   = 'ScomDataWarehouseSetting:ScomDataWarehouseSetting:WrongDatabaseName'
                Phrase = "Approval setting is $($setting.DataWarehouseDatabaseName) but should be $($this.DatabaseName)"
            }
        }
    
        return @{
            IsSingleInstance = $this.IsSingleInstance
            DatabaseName     = $setting.DataWarehouseDatabaseName
            ServerName       = $setting.DataWarehouseServerName
            Reasons          = $reasonList
        } 
    }

    [void] Set()
    {

        $parameters = @{
            ErrorAction  = 'Stop'
            DatabaseName = $this.DatabaseName
            ServerName   = $this.ServerName
        }
    
        Set-ScomDataWarehouseSetting @parameters   
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