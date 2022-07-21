# cScom

Class-based DSC resources to manage SCOM components as well as install SCOM. Looking for a schema-based (MOF) resource instead? Go to <https://github.com/dsccommunity/xscom>.

## Resources

### ScomComponent

This module expects some sanity in your choices when using the cScomComponent resource. This resource is
used for the installation or removal of **all** SCOM components. The possible combinations of parameters
are not validated. Rather, it is expected that you at least in principle know which parameters SCOM expects.
For your reference, these can be reviewed here: <https://docs.microsoft.com/en-us/system-center/scom/install-using-cmdline?view=sc-om-2022>

## ScomManagementPack

This resource allows you to import management packs either from file or from a string.

## ScomDiscovery

Configure discovery of an unsealed management pack, either using the `ClassName` parameter for an object class,
or the `GroupOrInstance` to specify groups and class instances.

`Discovery`, `ManagementPack`, `ClassName` are searched for in both `DisplayName` and `Name`. `GroupOrInstance` is only searched
for by `Name`.

## ScomMaintenanceSchedule

Configure a maintenance schedule for one or more objects.