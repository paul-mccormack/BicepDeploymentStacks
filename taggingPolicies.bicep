//Deployment Scope
targetScope = 'managementGroup'

@description('Array of enforced tags.  Consumed in bicepparam file.  Maximum 12 characters to keep within the 24 characters allowed for a Management Group scoped deployment')
@maxLength(12)
param tagNames array = []

@description('Contributor role definition id')
param roleDefinitionIdContributor string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' 

@description('Existing resource declaration for Contributor role')
resource contributorRoleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefinitionIdContributor
}

@description('Require tags on resource group policy definition')
resource requireTagOnRgPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'requireTagOnRg'
  scope: managementGroup()
  properties: {
    displayName: 'Require tag on resource group'
    policyType: 'Custom'
    mode: 'All'
    description: 'Required the specified tag when a resource group is created'
    parameters: {
      tagName: {
        type: 'String'
        metadata: {
          displayName: 'Tag Name'
          description: 'Required Tag'
        }
      }
    }
    metadata: {
      category: 'Tags'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: 'type'
            equals: 'Microsoft.Resources/subscriptions/resourceGroups'
          }
          {
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            exists: false
          }
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}

@description('Require tags on resource group policy assignment')
resource requireTagOnRgPolicyAssign 'Microsoft.Authorization/policyAssignments@2024-04-01' = [for name in tagNames:{
  name: 'tag-${name}-on-RG'
  scope: managementGroup()
  location: 'uksouth'
  properties: {
    displayName: 'Require tag ${name} on Resource Groups'
    description: 'Applies Tagging Policy to all Resource Groups'
    enforcementMode: 'Default'
    policyDefinitionId: requireTagOnRgPolicyDefinition.id
    parameters: {
      tagName: {
        value: name
      }
    }
    nonComplianceMessages: [
      {
        message: 'Denied By Tagging Policy Assignment'
      }
    ]
  }
}]

@description('Inherit tags from resource group policy definition')
resource inheritTagFromRgPolicyDefinition 'Microsoft.Authorization/policyDefinitions@2023-04-01' = {
  name: 'inheritTagFromRg'
  scope: managementGroup()
  properties: {
    displayName: 'Inherit a tag from the resource group if missing'
    policyType: 'Custom'
    mode: 'Indexed'
    description: 'Adds the specified tag and value from the parent resource group when any resource is created or updated, if it\'s missing.'
    parameters: {
      tagName: {
        type: 'String'
        metadata: {
          displayName: 'Tag Name'
          description: 'Required Tag'
        }
      }
    }
    metadata: { 
      category: 'Tags'
    }
    policyRule: {
      if: {
        allOf: [
          {
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            exists: false
          }
        ]
      }
      then: {
        effect: 'modify'
        details: {
          roleDefinitionIds: [
            contributorRoleDef.id
          ]
          operations: [
            {
            operation: 'addOrReplace'
            field: '[concat(\'tags[\', parameters(\'tagName\'), \']\')]'
            value: '[resourceGroup().tags[parameters(\'tagName\')]]'
          }
        ]
        }
      }
    }
  }
}

@description('Inherit tags from resource group policy assignment')
resource inheritTagPolicyAssign 'Microsoft.Authorization/policyAssignments@2024-04-01' = [for name in tagNames: {
  name: 'Tag-${name}-from-RG'
  scope: managementGroup()
  location: 'uksouth'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: inheritTagFromRgPolicyDefinition.id
    displayName: 'Inherit tag ${name} from Resource Group'
    parameters: {
      tagName: {
        value: name
      }
    }
  }
}]

@description('Role Assignment for inherit tags policy assignment')
resource inheritTagsFromRgRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for i in range(0, length(tagNames)): {
  name: guid(inheritTagPolicyAssign[i].name, inheritTagPolicyAssign[i].type)
  properties: {
    principalId: inheritTagPolicyAssign[i].identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDef.id
  }
}]
