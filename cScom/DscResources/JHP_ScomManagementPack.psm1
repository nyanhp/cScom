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

        if ($this.ManagementPackContent)
        {
            $tmpPath = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "$($this.Name).xml"
            $this.ManagementPackPath = New-Item -ItemType File -Path $tmpPath -Force
            Set-Content -Path $tmpPath -Force -Encoding Unicode -Value $this.ManagementPackContent
        }

        if ($this.ManagementPackPath)
        {
            Import-SCManagementPack -FullName $this.ManagementPackPath
        }
    }

    [bool] Test()
    {
        $currentState = $this.Get()

        return $($currentState.Reasons.Count -eq 0)
    }
}