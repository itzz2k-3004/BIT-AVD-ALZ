param AutomationAccountName string
param CloudEnvironment string
param Location string
param LogicAppName string
param RunbookNameGetHostPool string
param RunbookURI string
param SubscriptionId string
param Timestamp string
param Tags object

resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' existing = {
  name: AutomationAccountName
}

module runbookGetHostPoolInfo '../../../../../carml/1.3.0/Microsoft.Automation/automationAccounts/runbooks/deploy.bicep' = {
  name: 'carml_${RunbookNameGetHostPool}'
  params: {
    enableDefaultTelemetry: false
    name: RunbookNameGetHostPool
    automationAccountName: automationAccount.name
    description: 'AVD Metrics Runbook for collecting related Host Pool statistics to store in Log Analytics for specified Alert Queries'
    tags: contains(Tags, 'Microsoft.Automation/automationAccounts/runbooks') ? Tags['Microsoft.Automation/automationAccounts/runbooks'] : {}
    type: 'PowerShell'
    location: Location
    uri: RunbookURI
    version: '1.0.0.0'
  }
}

resource webhookGetHostPoolInfo 'Microsoft.Automation/automationAccounts/webhooks@2015-10-31' = {
  name: '${RunbookNameGetHostPool}_${dateTimeAdd(Timestamp, 'PT0H', 'yyyyMMddhhmmss')}'
  parent: automationAccount
  properties: {
    isEnabled: true
    expiryTime: dateTimeAdd(Timestamp, 'P5Y')
    runbook: {
      name: runbookGetHostPoolInfo.name
    }
  }
  dependsOn: [
    runbookGetHostPoolInfo
  ]
}

resource logicAppGetHostPoolInfo 'Microsoft.Logic/workflows@2016-06-01' = {
  name: LogicAppName
  tags: contains(Tags, 'Microsoft.Logic/workflows') ? Tags['Microsoft.Logic/workflows'] : {}
  dependsOn: [
    automationAccount
    runbookGetHostPoolInfo
  ]
  location: Location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        HTTP: {
          type: 'Http'
          inputs: {
            method: 'POST'
            uri: webhookGetHostPoolInfo.properties.uri
            body: {
              CloudEnvironment: CloudEnvironment
              SubscriptionId: SubscriptionId
            }
          }
        }
      }
      triggers: {
        Recurrence: {
          type: 'Recurrence'
          recurrence: {
            frequency: 'Minute'
            interval: 5
          }
        }
      }
    }
  }
}

