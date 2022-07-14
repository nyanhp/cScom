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

[DscResource()]
class ScomManagementPack
{
    [DscProperty(Key)] [System.String] $Name
    [DscProperty(Mandatory)] [System.Management.Automation.PSCredential] $SCOMAdminCredential
    [DscProperty(Mandatory)] [System.String] $SourceFilePath
    [DscProperty()] [Ensure] $Ensure = 'Present'
    [DscProperty(NotConfigurable)] [Reason[]] $Reasons

    [ScomManagementPack] Get()
    {
        
        return @{
            Name = $this.Name
            SCOMAdminCredential = $this.SCOMAdminCredential
            SourceFilePath = $this.SourceFilePath
            Ensure = $this.Ensure
            Reasons = @{
                Code = 'ScomManagementPack:ScomManagementPack:ManagementPackMissing'
                Phrase = "Management pack $($this.Name) missing."
            }
        }
    }

    [void] Set()
    {

    }

    [bool] Test()
    {
        return $true
    }
}