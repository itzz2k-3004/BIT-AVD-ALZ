# Automation Account Job Schedules `[Microsoft.Automation/automationAccounts/jobSchedules]`

This module deploys an Azure Automation Account Job Schedule.

## Navigation

- [Resource Types](#Resource-Types)
- [Parameters](#Parameters)
- [Outputs](#Outputs)
- [Cross-referenced modules](#Cross-referenced-modules)
- [Data Collection](#Data-Collection)

## Resource Types

| Resource Type | API Version |
| :-- | :-- |
| `Microsoft.Automation/automationAccounts/jobSchedules` | [2022-08-08](https://learn.microsoft.com/en-us/azure/templates/Microsoft.Automation/2022-08-08/automationAccounts/jobSchedules) |

## Parameters

**Required parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`runbookName`](#parameter-runbookname) | string | The runbook property associated with the entity. |
| [`scheduleName`](#parameter-schedulename) | string | The schedule property associated with the entity. |

**Conditional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`automationAccountName`](#parameter-automationaccountname) | string | The name of the parent Automation Account. Required if the template is used in a standalone deployment. |

**Optional parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`parameters`](#parameter-parameters) | object | List of job properties. |
| [`runOn`](#parameter-runon) | string | The hybrid worker group that the scheduled job should run on. |

**Generated parameters**

| Parameter | Type | Description |
| :-- | :-- | :-- |
| [`name`](#parameter-name) | string | Name of the Automation Account job schedule. Must be a GUID and is autogenerated. No need to provide this value. |

### Parameter: `runbookName`

The runbook property associated with the entity.

- Required: Yes
- Type: string

### Parameter: `scheduleName`

The schedule property associated with the entity.

- Required: Yes
- Type: string

### Parameter: `automationAccountName`

The name of the parent Automation Account. Required if the template is used in a standalone deployment.

- Required: Yes
- Type: string

### Parameter: `parameters`

List of job properties.

- Required: No
- Type: object
- Default: `{}`

### Parameter: `runOn`

The hybrid worker group that the scheduled job should run on.

- Required: No
- Type: string
- Default: `''`

### Parameter: `name`

Name of the Automation Account job schedule. Must be a GUID and is autogenerated. No need to provide this value.

- Required: No
- Type: string
- Default: `[newGuid()]`


## Outputs

| Output | Type | Description |
| :-- | :-- | :-- |
| `name` | string | The name of the deployed job schedule. |
| `resourceGroupName` | string | The resource group of the deployed job schedule. |
| `resourceId` | string | The resource ID of the deployed job schedule. |

## Cross-referenced modules

_None_

## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the [repository](https://aka.ms/avm/telemetry). There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.