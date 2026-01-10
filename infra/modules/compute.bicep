param location string
param projectName string

param adminUsername string
@secure()
param adminPassword string

param vmSku string
param instanceCount int

param snetWebId string

param logAnalyticsWorkspaceCustomerId string
@secure()
param logAnalyticsWorkspaceKey string

param sqlPrivateFqdn string

var vmssName = '${projectName}-vmss'

// Must match the LB name in network.bicep
var lbName = '${projectName}-lb'
var beName = 'be'

// Reference existing LB created by network module
resource lb 'Microsoft.Network/loadBalancers@2023-11-01' existing = {
  name: lbName
}

var backendPoolId = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, beName)

// Safe, compile-friendly script (no broken quoting)
var cmd = 'powershell -ExecutionPolicy Bypass -Command "Install-WindowsFeature Web-Server; $fqdn=''''${sqlPrivateFqdn}''''; $html=''<!doctype html><html><body><h1>${projectName} - VMSS behind Load Balancer</h1><p>Private SQL FQDN: '' + $fqdn + ''</p></body></html>''; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value $html"'

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    upgradePolicy: {
      mode: 'Automatic'
    }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-datacenter-azure-edition'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      }
      osProfile: {
        computerNamePrefix: '${projectName}-web'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: { id: snetWebId }
                    loadBalancerBackendAddressPools: [
                      { id: backendPoolId }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: { enabled: true }
      }
      extensionProfile: {
        extensions: [
          {
            name: 'IISSetup'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                commandToExecute: cmd
              }
            }
          }
          {
            name: 'MicrosoftMonitoringAgent'
            properties: {
              publisher: 'Microsoft.EnterpriseCloud.Monitoring'
              type: 'MicrosoftMonitoringAgent'
              typeHandlerVersion: '1.0'
              autoUpgradeMinorVersion: true
              settings: {
                workspaceId: logAnalyticsWorkspaceCustomerId
              }
              protectedSettings: {
                workspaceKey: logAnalyticsWorkspaceKey
              }
            }
          }
        ]
      }
    }
  }
}

// Autoscale on CPU
resource autoscale 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  name: '${projectName}-vmss-autoscale'
  location: location
  properties: {
    enabled: true
    targetResourceUri: vmss.id
    profiles: [
      {
        name: 'cpu-profile'
        capacity: {
          minimum: '2'
          maximum: '5'
          default: string(instanceCount)
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 70
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 30
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
        ]
      }
    ]
  }
}

output vmssId string = vmss.id

