# cScom

Class-based DSC resources to manage SCOM components as well as install SCOM. Looking for a schema-based (MOF) resource instead? Go to <https://github.com/dsccommunity/xscom>.

## Resources

### cScomComponent

This module expects some sanity in your choices when using the cScomComponent resource. This resource is
used for the installation or removal of **all** SCOM components. The possible combinations of parameters
are not validated. Rather, it is expected that you at least in principle know which parameters SCOM expects.
For your reference, these can be reviewed here: <https://docs.microsoft.com/en-us/system-center/scom/install-using-cmdline?view=sc-om-2022>

## cScomManagementPack

This resource allows you to import management packs either from file or from a string.