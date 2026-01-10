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
// shared key is needed by VM extension; safe enough for demo, but keep params secure
output workspaceSharedKey string = listKeys(law.id, law.apiVersion).primarySharedKey

