@description('The value of the Environment tag.')
@allowed([
  'dev'
  'stage'
  'prod'
])
param environmentTag string

@description('The name of the owner of the resources. This is used with the Owner tag.')
param ownerTag string

@description('The description of the resources. This is used with the Description tag.')
@minLength(1)
param descriptionTag string

@description('The prefix to use for the name of the resources.')
param namePrefix string = 'gs1au'

@description('The name of your hosting plan.  This will be prefixed with the namePrefix parameter.')
@minLength(1)
param name string

@description('The Azure region into which the resources should be deployed.  Defaults to the resource group location.')
param location string = resourceGroup().location  

@description('The kind of hosting plan to create.  Defaults to app.')
@allowed([
  'functionapp'
  'functionapp,linux'
])
param kind string = 'functionapp,linux'

param reserved bool = true

var generatedName = '${namePrefix}-${name}-plan'

@description('Creates/updates a hosting plan for a web or function app.')
resource hosting_plan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: generatedName
  location: location
  kind: kind
  tags: {
    Description: descriptionTag
    Environment: environmentTag
    Owner: ownerTag
  }
  properties: {
    reserved: reserved
  }
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
}

output hostingPlanId string = hosting_plan.id
