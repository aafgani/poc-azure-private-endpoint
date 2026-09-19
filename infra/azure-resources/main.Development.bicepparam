//Please deploy all within resource group GS1AU-Rg-NPCX-Dev

using 'main.bicep'

param environmentTag = 'dev'
param descriptionTag = 'Private Endpoint Function'

param name = 'private-endpoint-func'
param reserved = true

param connectionStrings = [
  {
    name: 'DefaultConnection'
    value: 'tobeupdated'
    type: 2
    slotSetting: false
  }
]

