param name string
param location string
param avdAgentPackageLocation string
param aadJoin bool
param mdmId string
param hostPoolName string
param systemData object = {}


//@secure()
param hostPoolToken string

/* Add session hosts to Host Pool */

@description('Calls the AVD DSC Script to Join the Session Hosts to the Host Pool. Parameters included to join to Azure AD and enroll in Intune')
resource addToHostPool 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: '${name}/Microsoft.PowerShell.DSC'
  location: location
  properties: {
    publisher: 'Microsoft.PowerShell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: avdAgentPackageLocation
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: hostPoolName
        registrationInfoToken: hostPoolToken
        aadJoin: aadJoin
        mdmId: aadJoin ? mdmId : ''
        sessionHostConfigurationLastUpdateTime: contains(systemData,'hostpoolUpdate') ? systemData.sessionHostConfigurationVersion : ''
      }
    }
  }
}
