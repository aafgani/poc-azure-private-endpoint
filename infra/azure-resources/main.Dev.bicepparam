//Please deploy all within resource group GS1AU-Rg-NPCX-Dev

using 'main.bicep'

param location = 'australiasoutheast'
param environmentTag = 'Dev'
param descriptionTag = 'Private Function App'

param name = 'NpcxFuncApp'
param reserved = true

param connectionStrings = [
  {
    name: 'DefaultConnection'
    value: 'tobeupdated'
    type: 2
    slotSetting: false
  }
]

