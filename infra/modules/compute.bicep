param location string
param projectName string
param adminUsername string
@secure()
param adminPassword string
param snetWebId string
param lbFrontendPublicIpId string

var lbName = 'lb-${projectName}'
var vmssName = 'vmss-${projectName}'

resource lb 'Microsoft.Network/loadBalancers@2023-11-01' = {
  name: lbName
  location: location
  sku: { name: 'Standard' }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'fe'
        properties: {
          publicIPAddress: { id: lbFrontendPublicIpId }
        }
      }
    ]
    backendAddressPools: [
      { name: 'be' }
    ]
    probes: [
      {
        name: 'httpProbe'
        properties: {
          protocol: 'Tcp'
          port: 80
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'httpRule'
        properties: {
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          frontendIPConfiguration: { id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', lbName, 'fe') }
          backendAddressPool: { id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'be') }
          probe: { id: resourceId('Microsoft.Network/loadBalancers/probes', lbName, 'httpProbe') }
        }
      }
    ]
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-03-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_D2s_v5'
    tier: 'Standard'
    capacity: 2
  }
  properties: {
    upgradePolicy: { mode: 'Automatic' }
    virtualMachineProfile: {
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-datacenter-g2'
          version: 'latest'
        }
        osDisk: { createOption: 'FromImage' }
      }
      osProfile: {
        computerNamePrefix: 'web'
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: 'ipconfig'
                  properties: {
                    subnet: { id: snetWebId }
                    loadBalancerBackendAddressPools: [
                      { id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lbName, 'be') }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'iisInstall'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -Command "Install-WindowsFeature Web-Server; Set-Content -Path C:\\inetpub\\wwwroot\\index.html -Value ''<h1>Secure Web App behind Azure Load Balancer</h1><p>Deployed via Bicep</p>''"'
              }
            }
          }
        ]
      }
    }
  }
}

output vmssId string = vmss.id
