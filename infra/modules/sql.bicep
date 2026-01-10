param location string
param projectName string

param sqlAdminUsername string
@secure()
param sqlAdminPassword string

param vnetId string
param snetDataId string

var sqlHostSuffix = environment().suffixes.sqlServerHostname // e.g. database.windows.net
var privateZoneName = 'privatelink.${sqlHostSuffix}'

var sqlServerName = toLower('${projectName}sql${uniqueString(resourceGroup().id)}')
var dbName = '${projectName}-db'

// Private DNS zone for SQL
resource sqlPrivateDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateZoneName
  location: 'global'
}

resource dnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${projectName}-dnslink'
  parent: sqlPrivateDns
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
  name: dbName
  parent: sqlServer
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

// DNS zone group attaches the private endpoint to the private DNS zone
resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  name: 'sql-zonegroup'
  parent: pe
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
output sqlPrivateFqdn string = '${sqlServer.name}.${sqlHostSuffix}'
