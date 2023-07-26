param Location string

resource deployTemplateSpec 'Microsoft.Resources/templateSpecs@2022-02-01' = {
  name: 'spec-avd-session-hosts'
  location: Location
  properties: {
    description: 'This is the template used by AVD Replacement Plan to deploy session hosts.'
    displayName: 'AVD Session Host Template'
  }
  resource deployTemplateSpecVersion 'versions@2022-02-01' = {
    name: 'deployTemplateSpecVersion'
    location: Location
    properties: {
      mainTemplate: loadJsonContent('../../../arm/avdSessionHosts.json')
    }
  }
}
