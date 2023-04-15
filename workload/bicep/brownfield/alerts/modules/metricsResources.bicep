param _ArtifactsLocation string
@secure()
param _ArtifactsLocationSasToken string
param ActionGroupName string
param ActivityLogAlerts array
param ANFVolumeResourceIds array
param AutomationAccountName string
param DistributionGroup string
//param FunctionAppName string
//param HostingPlanName string
//param HostPoolResourceGroupNames array
param HostPools array
param Location string
param LogAnalyticsWorkspaceResourceId string
param LogAlerts array
param LogAlertsHostPool array
//param LogAnalyticsWorkspaceName string
param LogicAppName string
param MetricAlerts object
param RunbookNameGetStorage string
param RunbookNameGetHostPool string
param RunbookScriptGetStorage string
param RunbookScriptGetHostPool string
param StorageAccountResourceIds array
param Tags object
param Timestamp string = utcNow('u')
param UsrAssignedId string

// var Environment = environment().name
var SubscriptionId = subscription().subscriptionId
var CloudEnvironment = environment().name
var AVDResIDsString = string(HostPools)
//var AVDResIDsQuotes = replace(AVDResIDsString, ',', '","')
var HostPoolsAsString = replace(replace(AVDResIDsString, '[', ''), ']', '')

module actionGroup '../../../../../carml/1.3.0/Microsoft.Insights/actionGroups/deploy.bicep' = {
  name: 'carml_${ActionGroupName}'
  params: {
    emailReceivers: [
      DistributionGroup
    ]
    enabled: true
    location: 'global'
    name: ActionGroupName
    groupShortName: 'EmailAlerts-AVDAlerts'
    tags: contains(Tags, 'Microsoft.Insights/actionGroups') ? Tags['Microsoft.Insights/actionGroups'] : {}
  }
}

module deploymentScript_HP2VM '../../../../../carml/1.3.0/Microsoft.Resources/deploymentScripts/deploy.bicep' = {
  name: 'carml_ds-PS-GetHostPoolVMAssociation'
  params: {
    arguments: '-AVDResourceIDs ${HostPoolsAsString}'
    azPowerShellVersion: '7.1'
    name: 'ds_GetHostPoolVMAssociation'
    primaryScriptUri: '${_ArtifactsLocation}dsHostPoolVMMap.ps1${_ArtifactsLocationSasToken}'
    userAssignedIdentities: {
      '${UsrAssignedId}': {}
    }
    kind: 'AzurePowerShell'
    location: Location
    timeout: 'PT2H'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D'
  }
}

module metricAlertsVMs 'metricAlertsVMs.bicep' = [for i in range(0, length(HostPools)): {
  name: 'linked_VMMetricAlerts_${guid(HostPools[i])}'
  params: {
    HostPoolInfo: json(deploymentScript_HP2VM.outputs.outputs.HostPoolInfo)[i]
    MetricAlerts: MetricAlerts
    Enabled: false
    AutoMitigate: false
    Location: Location
    ActionGroupId: actionGroup.outputs.resourceId
    Tags: Tags
  }
}]

module storAccountMetric 'storAccountMetric.bicep' = [for i in range(0, length(StorageAccountResourceIds)): if (length(StorageAccountResourceIds) > 0) {
  name: 'MetricAlert_StorageAccount_${split(StorageAccountResourceIds[i], '/')[8]}'
  params: {
    AutoMitigate: false
    Enabled: false
    Location: Location
    StorageAccountResourceID: StorageAccountResourceIds[i]
    MetricAlertsStorageAcct: MetricAlerts.storageAccounts
    ActionGroupID: actionGroup.outputs.resourceId
    Tags: Tags
  }
}]

module azureNetAppFilesMetric 'anfMetric.bicep' = [for i in range(0, length(ANFVolumeResourceIds)): if (length(ANFVolumeResourceIds) > 0) {
  name: 'MetricAlert_ANF_${split(ANFVolumeResourceIds[i], '/')[12]}'
  params: {
    AutoMitigate: false
    Enabled: false
    Location: Location
    ANFVolumeResourceID: ANFVolumeResourceIds[i]
    MetricAlertsANF: MetricAlerts.anf
    ActionGroupID: actionGroup.outputs.resourceId
    Tags: Tags
  }
}]

// If Metric Namespace contains file services ; change scopes to append default
// module to loop through each scope time as it MUST be a single Resource ID
module fileServicesMetric 'fileservicsmetric.bicep' = [for i in range(0, length(StorageAccountResourceIds)): if (length(StorageAccountResourceIds) > 0) {
  name: 'linked_MetricAlerts-FileServices_${i}'
  params: {
    AutoMitigate: false
    Enabled: false
    Location: Location
    StorageAccountResourceID: StorageAccountResourceIds[i]
    MetricAlertsFileShares: MetricAlerts.fileShares
    ActionGroupID: actionGroup.outputs.resourceId
    Tags: Tags
  }
}]

module logAlertQueries '../../../../../carml/1.3.0/Microsoft.Insights/scheduledQueryRules/deploy.bicep' = [for i in range(0, length(LogAlerts)): {
  name: 'carml_${LogAlerts[i].name}'
  params: {
    name: LogAlerts[i].name
    autoMitigate: false
    criterias: LogAlerts[i].criteria
    scopes: [ LogAnalyticsWorkspaceResourceId ]
    location: Location
    actions: [ {
        actionGroups: [
          actionGroup.outputs.resourceId
        ]
        customProperties: {}
      } ]
    alertDescription: LogAlerts[i].description
    enabled: false
    evaluationFrequency: LogAlerts[i].evaluationFrequency
    severity: LogAlerts[i].severity
    tags: contains(Tags, 'Microsoft.Insights/scheduledQueryRules') ? Tags['Microsoft.Insights/scheduledQueryRules'] : {}
    windowSize: LogAlerts[i].windowSize
  }
}]

module logAlertHostPoolQueries 'hostPoolAlerts.bicep' = [for hostpool in HostPools: {
  name: 'linked_HostPoolAlerts-${guid(hostpool, subscription().id)}'
  params: {
    AutoMitigate: false
    ActionGroupId: actionGroup.outputs.resourceId
    HostPoolName: split(hostpool, '/')[8]
    Location: Location
    LogAlertsHostPool: LogAlertsHostPool
    LogAnalyticsWorkspaceResourceId: LogAnalyticsWorkspaceResourceId
    Tags: {}
  }
}]

// Currently only deploys IF Cloud Environment is Azure Commercial Cloud
module activityLogAlerts '../../../../../carml/1.3.0/Microsoft.Insights/activityLogAlerts/deploy.bicep' = [for i in range(0, length(ActivityLogAlerts)): if (CloudEnvironment == 'AzureCloud') {
  name: 'carml_${LogAlerts[i].name}'
  params: {
    name: ActivityLogAlerts[i].name
    enabled: false
    location: 'Global'
    tags: contains(Tags, 'Microsoft.Insights/activityLogAlerts') ? Tags['Microsoft.Insights/activityLogAlerts'] : {}
    scopes: [
      '/subscriptions/${SubscriptionId}'
    ]
    conditions: [
      {
        allOf: [
          {
            field: 'category'
            equals: 'ServiceHealth'
          }
          {
            anyOf: ActivityLogAlerts[i].anyof
          }
          {
            field: 'properties.impactedServices[*].ServiceName'
            containsAny: [
              'Windows Virtual Desktop'
            ]
          }
          {
            field: 'properties.impactedServices[*].ImpactedRegions[*].RegionName'
            containsAny: [
              Location
            ]
          }
        ]
      }
    ]
    actions: [
      {
        actionGroups: [
          {
            actionGroupId: actionGroup.outputs.resourceId
          }
        ]
      }
    ]
    alertDescription: ActivityLogAlerts[i].description
  }
}]

module logicApp_Storage './logicApp_Storage.bicep' = if (length(StorageAccountResourceIds) > 0) {
  name: 'LogicApp_Storage'
  params: {
    AutomationAccountName: AutomationAccountName
    CloudEnvironment: CloudEnvironment
    Location: Location
    LogicAppName: '${LogicAppName}-Storage'
    RunbookNameGetStorage: RunbookNameGetStorage
    RunbookURI: '${_ArtifactsLocation}${RunbookScriptGetStorage}'
    StorageAccountResourceIds: StorageAccountResourceIds
    Timestamp: Timestamp
    Tags: Tags
  }
}

module logicApp_HostPool './logicApp_HostPool.bicep' = {
  name: 'LogicApp_HostPool'
  params: {
    AutomationAccountName: AutomationAccountName
    CloudEnvironment: CloudEnvironment
    Location: Location
    LogicAppName: '${LogicAppName}-HostPool'
    RunbookNameGetHostPool: RunbookNameGetHostPool
    RunbookURI: '${_ArtifactsLocation}${RunbookScriptGetHostPool}'
    SubscriptionId: SubscriptionId
    Timestamp: Timestamp
    Tags: Tags
  }
}
