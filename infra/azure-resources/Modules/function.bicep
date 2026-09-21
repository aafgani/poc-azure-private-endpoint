@description('The value of the Environment tag.')
@allowed([
  'dev'
  'stage'
  'prod'
])
param environmentTag string = 'dev'

@description('The name of the owner of the resources. This is used with the Owner tag.')
param ownerTag string = 'BIT'

@description('The description of the resources. This is used with the Description tag.')
@minLength(1)
param descriptionTag string

@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The prefix to use for the name of the resources.  This will be preceded by anzca and followed by the environmentTag and the name of the resource.')
param namePrefix string = 'gs1au'

@description('The name of your Function App.')
param name string = 'fa-${uniqueString(resourceGroup().id)}'

@description('Resource Id of the hosting plan.')
@minLength(1)
param hostingPlanId string


@description('The app settings to configure for the Function App.  This should be an array of objects with name and value properties.')
param appSettings array = [
    {
      name: 'ConfigName'
      value: 'ConfigValue'
    }
]

@description('The connection strings to configure for the Function App.  This should be an array of objects with name, value, type and slotSetting properties.')
param connectionStrings array = [
  {
    name: 'DefaultConnection'
    value: 'tobeupdated'
    type: 2
    slotSetting: false
  }
]

param appInsightsConnectionString string = ''

@description('The kind of hosting plan to create.  Defaults to app.')
@allowed([
  'functionapp'
  'functionapp,linux'
])
param kind string = 'functionapp,linux'

@description('Resource ID of the subnet used for Function App VNet integration.')
param functionIntegrationSubnetId string

var generatedStorageName = toLower('${namePrefix}${name}stg')
var generatedName = '${namePrefix}-${name}-func'
var deploymentContainerName = 'function-releases'

var combinedAppSettings = sys.concat(
  [
    {
      name: 'FUNCTIONS_EXTENSION_VERSION'
      value: '~4'
    }
    {
      name: 'AzureWebJobsStorage'
      value: 'DefaultEndpointsProtocol=https;AccountName=${generatedStorageName};AccountKey=${storageAccount.listKeys().keys[0].value}'
    }
    {
      name: 'APPINSIGHTS_CONNECTION_STRING'
      value: appInsightsConnectionString
    }
    {
      name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
      value: true
    }
    {
      name: 'WEBSITE_USE_PLACEHOLDER_DOTNETISOLATED'
      value: 1
    }
    {
      name: 'DEPLOYMENT_STORAGE_CONNECTION_STRING'
      value: 'DefaultEndpointsProtocol=https;AccountName=${generatedStorageName};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    }
    
  ],
  appSettings
)

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: generatedStorageName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: '${storageAccount.name}/default/${deploymentContainerName}'
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: generatedName
  location: location
  tags: {
    Description: descriptionTag
    Environment: environmentTag
    Owner: ownerTag
  }
  kind: kind
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    enabled: true
    serverFarmId: hostingPlanId
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: 'https://${generatedStorageName}.blob.${environment().suffixes.storage}/${deploymentContainerName}'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'DEPLOYMENT_STORAGE_CONNECTION_STRING'
          }
        }
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '10.0'
      }
      scaleAndConcurrency: {
        maximumInstanceCount: 200
        instanceMemoryMB: 2048
      }
    }
    vnetRouteAllEnabled: false
    vnetImagePullEnabled: false
    vnetContentShareEnabled: false
    siteConfig: {
      numberOfWorkers: 1
      acrUseManagedIdentityCreds: false
      alwaysOn: false
      http20Enabled: false
      minimumElasticInstanceCount: 0
      appSettings: combinedAppSettings
      connectionStrings: connectionStrings
      scmIpSecurityRestrictionsDefaultAction: 'Allow'
      scmIpSecurityRestrictionsUseMain: true
    }
    scmSiteAlsoStopped: false
    clientAffinityEnabled: true
    httpsOnly: true

    publicNetworkAccess: 'Enabled'
    keyVaultReferenceIdentity: 'SystemAssigned'
  }
  dependsOn: [
    deploymentContainer
  ]
}

resource site_web 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    numberOfWorkers: 1
    netFrameworkVersion: 'v10.0'
    use32BitWorkerProcess: false
    webSocketsEnabled: false
    managedPipelineMode: 'Integrated'
    scmType: 'VSTSRM'
    http20Enabled: false
    minTlsVersion: '1.2'
    scmMinTlsVersion: '1.2'
  }
}

resource functionAppVnetIntegration 'Microsoft.Web/sites/virtualNetworkConnections@2024-04-01' = {
  parent: functionApp
  name: 'vnet'
  properties: {
    subnetResourceId: functionIntegrationSubnetId
  }
}

output functionAppManagedIdentity string = functionApp.identity.principalId
