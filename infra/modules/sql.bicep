param location string
param projectName string
param vnetId string
param snetDataId string

var sqlServerName = 'sql-${uniqueString(resourceGroup().id, projectName)}'
var dbName = 'appdb'

resource sql 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: 'sqladminuser'
    administratorLoginPassword: 'ChangeMe-In-ParamsOrKeyVault' // for demo; improve later with Key Vault
    publicNetworkAccess: 'Disabled'
  }
}

resource db 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sql
  name: dbName
  sku: { name: 'Basic', tier: 'Basic' }
}

resource privateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
}

resource dnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-${projectName}'
  parent: privateDns
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

resource pe 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-sql-${projectName}'
  location: location
  properties: {
    subnet: { id: snetDataId }
    privateLinkServiceConnections: [
      {
        name: 'sqlConnection'
        properties: {
          privateLinkServiceId: sql.id
          groupIds: [ 'sqlServer' ]
        }
      }
    ]
  }
}

resource peDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: 'sql-dns'
  parent: pe
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: { privateDnsZoneId: privateDns.id }
      }
    ]
  }
}

output sqlServerName string = sql.name
output sqlDatabaseName string = db.name
