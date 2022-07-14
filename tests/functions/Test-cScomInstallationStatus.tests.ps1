if (-not (Get-Command -Name Get-WebSite -ErrorAction SilentlyContinue))
{
    function Get-WebSite {}
}   

$casesPresent = @(
    @{
        ScomComponent = @{
            Role             = 'NativeConsole'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
        Invokes       = 'Get-Package'
    }
    @{
        ScomComponent = @{
            Role             = 'WebConsole'
            WebSiteName      = 'Default Web Site'
            ManagementServer = 'MG1'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
        Invokes       = 'Get-WebSite'
    }
    @{
        ScomComponent = @{
            Role             = 'FirstManagementServer'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
        Invokes       = 'Get-Package'
    }
    @{
        ScomComponent = @{
            Role             = 'AdditionalManagementServer'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
        Invokes       = 'Get-Package'
    }
    @{
        ScomComponent = @{
            Role             = 'ReportServer'
            Ensure           = 'Present'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
        Invokes       = 'Get-Package'
    }
)
            
                
$casesAbsent = @(
    @{
        ScomComponent = @{
            Role             = 'NativeConsole'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
    }
    @{
        ScomComponent = @{
            Role             = 'WebConsole'
            WebSiteName      = 'Default Web Site'
            ManagementServer = 'MG1'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
    }
    @{
        ScomComponent = @{
            Role             = 'FirstManagementServer'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
    }
    @{
        ScomComponent = @{
            Role             = 'AdditionalManagementServer'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
    }
    @{
        ScomComponent = @{
            Role             = 'ReportServer'
            Ensure           = 'Absent'
            IsSingleInstance = 'Yes'
            SourcePath       = 'ThisIsATest'
            InstallLocation  = 'C:\Program Files\Microsoft System Center\Operations Manager'
        }
    }
)

. (Resolve-Path "$global:testroot\..\cScom\classes\JHP_Ensure.ps1").Path
. (Resolve-Path "$global:testroot\..\cScom\classes\JHP_Reason.ps1").Path
. (Resolve-Path "$global:testroot\..\cScom\classes\JHP_Role.ps1").Path
Import-Module -Name PowerShellGet -Force

Describe 'Test-cScomInstallationStatus' {
    Context GoodCaseGetPackageExists -Skip {
        BeforeAll {
            Mock -CommandName Get-Command -MockWith { return 'A command' } -Verifiable -ModuleName cScom
            Mock -CommandName Get-Website -MockWith { return 'A Website' } -Verifiable -ModuleName cScom
            Mock -CommandName Get-Package -MockWith { return 'A Package' } -Verifiable -ModuleName cScom -ParameterFilter { $Name -like 'System Center Operations Manager*' }
        }
        It 'Role "<ScomComponent.Role>" Ensure:Present, Get-Package exists, should return True' -TestCases $casesPresent {
            Write-Host ($ScomComponent | Out-String)
            WRite-Host $Invokes
            Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -BeTrue
            Should -Invoke $Invokes
        }
        It 'Role "<ScomComponent.Role>" Ensure:Absent, Get-Package exists, should return False' -TestCases $casesAbsent {
            Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -Not -BeTrue
            Should -Invoke $Invokes
        }
    }

    Context GoodCaseGetPackageMissing -Skip {
        BeforeAll {
            Mock -CommandName Get-Website -MockWith { 'A Website' } -Verifiable -ModuleName cScom
            Mock -CommandName Get-Command -MockWith {} -ParameterFilter { $Name -eq 'Get-Package' } -Verifiable -ModuleName cScom
            Mock -CommandName Test-Path -MockWith { $true } -Verifiable -ModuleName cScom
        }

        It 'Role "<ScomComponent.Role>" Ensure:Present, Get-Package not available, should return True' -TestCases $casesPresent {
            Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -Be $true
        }

        It 'Role "<ScomComponent.Role>" Ensure:Absent, Get-Package not available, should return False' -TestCases $casesAbsent {
            Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -Be $false
        }

        It 'Should have walked all code paths' {
            Should -InvokeVerifiable
        }
    }

    Context BadCase {

    }
}