param location string
param projectName string
param sqlAdminUsername string
@secure()
param sqlAdminPassword string

param vnetId string
param snetDataId string

var sqlServerName = toLower('${projectName}sql${uniqueString(resourceGroup().id)}')
var dbName = '${projectName}-db'

// Private DNS zone for SQL
resource sqlPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.database.windows.net'
  location: 'global'
}

resource dnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${sqlPrivateDns.name}/${projectName}-dnslink'
  location: 'global'
  properties: {
    virtualNetwork: { id: vnetId }
    registrationEnabled: false
  }
}

// SQL Server (public network disabled)
resource sqlServer 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminUsername
    administratorLoginPassword: sqlAdminPassword
    publicNetworkAccess: 'Disabled'
    minimalTlsVersion: '1.2'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: '${sqlServer.name}/${dbName}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Basic'
  }
  properties: {
    maxSizeBytes: 2147483648
  }
}

// Private endpoint to SQL
resource pe 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${projectName}-sql-pe'
  location: location
  properties: {
    subnet: { id: snetDataId }
    privateLinkServiceConnections: [
      {
        name: 'sql-conn'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [ 'sqlServer' ]
        }
      }
    ]
  }
}

// DNS A-record is created by a zone group
resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: '${pe.name}/sql-zonegroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sqlDns'
        properties: {
          privateDnsZoneId: sqlPrivateDns.id
        }
      }
    ]
  }
}

output sqlServerName string = sqlServer.name
output sqlDatabaseName string = dbName
output sqlPrivateFqdn string = '${sqlServer.name}.database.windows.net'

