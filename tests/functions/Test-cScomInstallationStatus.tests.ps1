BeforeDiscovery {
    if (-not (Get-Command -Name Get-WebSite -ErrorAction SilentlyContinue))
    {
        function global:Get-WebSite {}
    }

    function Get-Package
    {
        [CmdletBinding()]
        param
        (
            [Parameter()]
            [string]
            $ProviderName,

            [Parameter()]
            [string]
            $Name
        )
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
}

InModuleScope -ModuleName cScom {
    Describe 'Test-cScomInstallationStatus' {
        Context GoodCaseGetPackageExists {
            BeforeEach {
                Mock -CommandName Get-Command -MockWith { return 'A command' } -Verifiable
                Mock -CommandName Get-Website -MockWith { return 'A Website' } -Verifiable
                Mock -CommandName Get-Package -MockWith { return 'A Package' } -Verifiable -ParameterFilter { $Name -like 'System Center Operations Manager*' }
            }
            It 'Role "<ScomComponent.Role>" Ensure:Present, Get-Package exists, should return True' -TestCases $casesPresent {
                Test-cScomInstallationStatus -ScomComponent $ScomComponent -Verbose | Should -BeTrue
                if ($Invokes) { Should -Invoke $Invokes }
            }
            It 'Role "<ScomComponent.Role>" Ensure:Absent, Get-Package exists, should return False' -TestCases $casesAbsent {
                Mock -CommandName Get-Package -MockWith { return $false } -Verifiable -ParameterFilter { $Name -like 'System Center Operations Manager*' }
                Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -Not -BeTrue
                if ($Invokes) { Should -Invoke $Invokes }
            }
        }

        Context GoodCaseGetPackageMissing {
            BeforeEach {
                Mock -CommandName Get-Website -MockWith { 'A Website' } -Verifiable
                Mock -CommandName Get-Command -MockWith {} -ParameterFilter { $Name -eq 'Get-Package' } -Verifiable
                Mock -CommandName Test-Path -MockWith { $true } -Verifiable
            }

            It 'Role "<ScomComponent.Role>" Ensure:Present, Get-Package not available, should return True' -TestCases $casesPresent {
                Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -Be $true
            }

            It 'Role "<ScomComponent.Role>" Ensure:Absent, Get-Package not available, should return False' -TestCases $casesAbsent {
                Test-cScomInstallationStatus -ScomComponent $ScomComponent | Should -Be $false
            }

            It 'Should have walked all code paths' -TestCases $casesPresent {
                $null = Test-cScomInstallationStatus -ScomComponent $ScomComponent
                Should -InvokeVerifiable
            }
        }

        Context BadCase {

        }
    }
}