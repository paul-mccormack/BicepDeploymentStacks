//Deployment Scope
targetScope = 'managementGroup'

@description('Name of policy set assignment. 24 char max as scope is Management Group')
@maxLength(24)
param policySetAssignmentName string = 'GuestConfigurationPreReq'

@description('Policy definition Id')
param policySetDefinitionId string = '/providers/Microsoft.Authorization/policySetDefinitions/12794019-7a00-42cf-95c2-882eed337cc8'

@description('Policy set display name')
param PolicySetDisplayName string = 'Deploy prerequisites to enable Guest Configuration policies on virtual machines'

@description('Contributor role definition id')
param roleDefinitionIdContributor string = 'b24988ac-6180-42a0-ab88-20f7382dd24c' 

@description('Existing resource declaration for Contributor role')
resource contributorRoleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefinitionIdContributor
}

@description('Policy assignment')
resource assignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: policySetAssignmentName
  scope: managementGroup()
  location: 'uksouth'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    policyDefinitionId: policySetDefinitionId
    displayName: PolicySetDisplayName
  }
}

@description('Role Assignment for system assigned managed identity')
resource guestCustPolicyAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(assignment.name, assignment.type)
  properties: {
    principalId: assignment.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: contributorRoleDef.id
  }
}
