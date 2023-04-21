param _ArtifactsLocation string
@secure()
param _ArtifactsLocationSasToken string
param ActionGroupName string
param ANFVolumeResourceIds array
param AutomationAccountName string
param DistributionGroup string
//param FunctionAppName string
//param HostingPlanName string
//param HostPoolResourceGroupNames array
param HostPools array
param Location string
param LogAnalyticsWorkspaceResourceId string
param LogAlertsStorage array
param LogAlertsHostPool array
param LogAlertsSvcHealth array
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
param UsrAssignedResourceId string

// var Environment = environment().name
var SubscriptionId = subscription().subscriptionId
var CloudEnvironment = environment().name
var AVDResIDsString = string(HostPools)
//var AVDResIDsQuotes = replace(AVDResIDsString, ',', '","')
var HostPoolsAsString = replace(replace(AVDResIDsString, '[', ''), ']', '')

module actionGroup '../../../../../carml/1.3.0/Microsoft.Insights/actionGroups/deploy.bicep' = {
  name: ActionGroupName
  params: {
    emailReceivers: [
      {
        emailAddress: DistributionGroup
        name: 'AVD Operations Admin(s)'
        useCommonAlertSchema: true
      }
    ]
    enabled: true
    location: 'global'
    enableDefaultTelemetry: false
    name: ActionGroupName
    groupShortName: 'AVDMetrics'
    tags: contains(Tags, 'Microsoft.Insights/actionGroups') ? Tags['Microsoft.Insights/actionGroups'] : {}
  }
}

module deploymentScript_HP2VM '../../../../../carml/1.3.0/Microsoft.Resources/deploymentScripts/deploy.bicep' = {
  name: 'carml_ds-PS-GetHostPoolVMAssociation'
  params: {
    enableDefaultTelemetry: false
    arguments: '-AVDResourceIDs ${HostPoolsAsString}'
    azPowerShellVersion: '7.1'
    name: 'ds_GetHostPoolVMAssociation'
    primaryScriptUri: '${_ArtifactsLocation}dsHostPoolVMMap.ps1${_ArtifactsLocationSasToken}'
    userAssignedIdentities: {
      '${UsrAssignedResourceId}' : {}
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
  dependsOn: [
    deploymentScript_HP2VM
  ]
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

module logAlertStorage '../../../../../carml/1.3.0/Microsoft.Insights/scheduledQueryRules/deploy.bicep' = [for i in range(0, length(LogAlertsStorage)): {
  name: LogAlertsStorage[i].name
  params: {
    enableDefaultTelemetry: false
    name: LogAlertsStorage[i].name
    autoMitigate: false
    criterias: LogAlertsStorage[i].criteria
    scopes: [ LogAnalyticsWorkspaceResourceId ]
    location: Location
    actions: [ {
        actionGroups: [
          actionGroup.outputs.resourceId
        ]
        customProperties: {}
      } ]
    alertDescription: LogAlertsStorage[i].description
    enabled: false
    evaluationFrequency: LogAlertsStorage[i].evaluationFrequency
    severity: LogAlertsStorage[i].severity
    tags: contains(Tags, 'Microsoft.Insights/scheduledQueryRules') ? Tags['Microsoft.Insights/scheduledQueryRules'] : {}
    windowSize: LogAlertsStorage[i].windowSize
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
module logAlertSvcHealth '../../../../../carml/1.3.0/Microsoft.Insights/activityLogAlerts/deploy.bicep' = [for i in range(0, length(LogAlertsSvcHealth)): if (CloudEnvironment == 'AzureCloud') {
  name: 'carml_${LogAlertsSvcHealth[i].name}'
  params: {
    enableDefaultTelemetry: false
    name: LogAlertsSvcHealth[i].name
    enabled: false
    location: 'global'
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
            anyOf: LogAlertsSvcHealth[i].anyof
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
    alertDescription: LogAlertsSvcHealth[i].description
  }
}]

module logicApp_Storage './logicApp_Storage.bicep' = if (length(StorageAccountResourceIds) > 0) {
  name: 'linked_LogicApp_Storage'
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
  name: 'linked_LogicApp_HostPool'
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
