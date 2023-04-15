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
}

module logicAppGetHostPoolInfo '../../../../../carml/1.2.1.old/Microsoft.Logic/workflows/deploy.bicep' = {
  name: 'carml-1.2.1_${LogicAppName}'
  params: {
    name: LogicAppName
    tags: contains(Tags, 'Microsoft.Logic/workflows') ? Tags['Microsoft.Logic/workflows'] : {}
    location: Location
    state: 'Enabled'
    workflowActions: {
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
    workflowTriggers: {
      Recurrence: {
        type: 'Recurrence'
        recurrence: {
          frequency: 'Minute'
          interval: 5
        }
      }
    }
  }
  dependsOn: [
    automationAccount
    runbookGetHostPoolInfo
  ]
}

