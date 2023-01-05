@{

    # Script module or binary module file associated with this manifest.
    RootModule           = 'cScom.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0.5'

    # ID used to uniquely identify this module
    GUID                 = 'b4632b7c-b7c6-4b99-ae83-f95199630ec0'

    # Author of this module
    Author               = 'Jan-Hendrik Peters'

    # Company or vendor of this module
    CompanyName          = 'Jan-Hendrik Peters'

    # Copyright statement for this module
    Copyright            = '(c) Jan-Hendrik Peters. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'DSC resources to deploy and configure SCOM. Major revamp of xScom.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules      = @(
        'AutomatedLab.Common'
        'DscResource.Base'
    )

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(
        'Get-cScomParameter'
        'Resolve-cScomModule'
        'Test-cScomInstallationStatus'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @()

    # DSC resources to export from this module
    DscResourcesToExport = @(
        'ScomComponent'
        'ScomManagementPack'
        'ScomDiscovery'
        'ScomMaintenanceSchedule'
        'ScomAgentApprovalSetting'
        'ScomAlertResolutionSetting'
        'ScomDatabaseGroomingSetting'
        'ScomDataWarehouseSetting'
        'ScomErrorReportingSetting'
        'ScomHeartbeatSetting'
        'ScomReportingSetting'
        'ScomWebAddressSetting'
    )

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = @('SCOM', 'DesiredStateConfiguration', 'DSC', 'DSCResource')

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/nyanhp/cScom/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri   = 'https://github.com/nyanhp/cScom'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = '[1.0.4] Compatibility with other resources by including DscResource.Base'

            # Prerelease string of this module
            Prerelease   = 'preview0002'

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable
}

