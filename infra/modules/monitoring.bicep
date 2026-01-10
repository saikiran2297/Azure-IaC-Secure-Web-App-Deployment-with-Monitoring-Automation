param location string
param projectName string

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${projectName}-law'
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

output workspaceId string = law.id
output workspaceCustomerId string = law.properties.customerId
// NOTE: This is used for the legacy MMA agent extension; it triggers a linter warning but compiles and works.
output workspaceSharedKey string = listKeys(law.id, law.apiVersion).primarySharedKey
