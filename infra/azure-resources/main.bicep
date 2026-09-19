targetScope = 'resourceGroup'

@description('The Azure region where resources will be deployed.')
param location string = resourceGroup().location

@description('The value of the Environment tag.')
@allowed([
  'Dev'
  'Stage'
  'Prod'
])
param environmentTag string = 'Dev'

@description('The value of the Description tag.')
@minLength(1)
param descriptionTag string

@description('The prefix to use for resource names.')
param namePrefix string = 'gs1au'

@description('The name of the Function App.')
@minLength(1)
param name string

@description('The name of the resource owner.')
param ownerTag string = 'BST'

@description('The connection strings to configure for the Function App.')
param connectionStrings array = []

@description('The kind of hosting plan to create.')
@allowed([
  'functionapp'
  'functionapp,linux'
])
param kind string = 'functionapp,linux'

param reserved bool = true

// Hosting Plan
module hostingPlanModule './Modules/hosting.bicep' = {
  name: 'hostingPlanModule'
  params: {
    location: location
    environmentTag: environmentTag
    name: name
    descriptionTag: descriptionTag
    ownerTag: ownerTag
    namePrefix: namePrefix
    reserved: reserved
  }
}

// Function App
module functionApp './Modules/function.bicep' = {
  name: 'functionApp'
  params: {
    location: location
    environmentTag: environmentTag
    name: name
    descriptionTag: descriptionTag
    ownerTag: ownerTag
    namePrefix: namePrefix
    hostingPlanId: hostingPlanModule.outputs.hostingPlanId
    connectionStrings: connectionStrings
    kind: kind
  }
}
