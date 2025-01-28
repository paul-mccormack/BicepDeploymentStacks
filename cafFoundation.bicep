//Deployment Scope
targetScope = 'managementGroup'

@description('Region for Policy Assignment Deployment.  Allowed UK South and UK West')
@allowed([
  'uksouth'
  'ukwest'
])
param location string

@description('Contributor role Id')
param roleDefinitionIdContributor string = '/providers/microsoft.authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c' 

@description('Name of policy set assignment. 24 char max as scope is Management Group')
@maxLength(24)
param cafFoundationPolicySetAssignName string = 'cafPolicySetAssign'

@description('Display name of policy set assignment. 24 char max as scope is Management Group')
@maxLength(24)
param cafFoundationPolicySetDefinitionName string = 'CAF Policy Set'

@description('Resource allowed locations policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param resourceLocationPolicyAssignmentName string = 'Allowed locations'

@description('Resource allowed locations policy definition Id')
param resourceLocationPolicyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'

@description('Resource group allowed locations policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param resourceGroupLocationPolicyAssignmentName string = 'Allowed locations for RG'

@description('Resource group allowed locations policy definition Id')
param resourceGroupLocationPolicyDefinitionId string = '/providers/microsoft.authorization/policydefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'

@description('Allowed locations array.  Consumed via bicepparam file')
param allowedLocations array = []

@description('Deploy network watcher policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param deployNetworkWatcherPolicyAssignmentName string = 'Deploy network watcher'

@description('Deploy network watcher policy definition Id')
param deployNetworkWatcherPolicyDefinitionId string = '/providers/microsoft.authorization/policydefinitions/a9b99dd8-06c5-4317-8629-9d86a3c6e7d9'

@description('Not allowed resources policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param notAllowedResourceTypesPolicyAssignmentName string = 'Not allowed resources'

@description('Not allowed resources policy definition Id')
param notAllowedResourceTypesPolicyDefinitionId string = '/providers/microsoft.authorization/policydefinitions/6c112d4e-5bc7-47ae-a041-ea2d9dccd749'

@description('Not allowed resources array.  Consumed via bicepparam file')
param notAllowedResources array = []

@description('Secure storage account transfer enabled policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param storageAccountSecureTransferEnabledPolicyAssignmentName string = 'Storage Account Transfer'

@description('Secure storage account transfer enabled policy definition Id')
param storageAccountSecureTransferEnabledPolicyPolicyDefinitionId string = '/providers/microsoft.authorization/policydefinitions/404c3081-a854-4457-ae30-26a93ef643f9'

@description('Allowed storage account Sku policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param allowedStorageAccountSkuPolicyAssignmentName string = 'Allowed Storage SKU'

@description('Allowed storage account sku policy definition Id')
param allowedStorageAccountSkuPolicyDefinitionId string = '/providers/microsoft.authorization/policydefinitions/7433c107-6db4-4ad1-b57a-a76dce0154a1'

@description('Allowed storage account sku array.  Consumed via bicepparam file')
param allowedStorageSku array = []

@description('Allowed VM sku policy assignment name. 24 char max as scope is Management Group')
@maxLength(24)
param allowedVmSkuPolicyAssignmentName string = 'Allowed VM SKU'

@description('Allowed VM sku policy definition Id')
param allowedVmSkuPolicyDefinitionId string = '/providers/microsoft.authorization/policydefinitions/cccc23c7-8427-4f53-ad12-b6a63eb452b3'

@description('Allowed VM sku array.  Consumed via bicepparam file')
param allowedVMSku array = []

@description('Role Assignment for CAF Foundation Policy Set Service Principal')
resource cafFoundationPolicySetRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(cafFoundationPolicySetAssign.name, cafFoundationPolicySetAssign.type)
  properties: {
    principalId: cafFoundationPolicySetAssign.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleDefinitionIdContributor
  }
}

@description('Policy Assignment for the CAF Policy Set')
resource cafFoundationPolicySetAssign 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: cafFoundationPolicySetAssignName
  scope: managementGroup()
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'Cloud Adoption Framework Foundation Policies'
    description: 'Applies the baseline policies set out in the Cloud Adoption Framework'
    enforcementMode: 'Default'
    policyDefinitionId: cafPolicySetDefinition.id
    nonComplianceMessages: [
      {
        message: 'Denied by Cloud Adoption Framework Foundation Policy Assignment'
      }
    ]
  }
}

@description('CAF Policy Set')
resource cafPolicySetDefinition 'Microsoft.Authorization/policySetDefinitions@2023-04-01' = {
  name: cafFoundationPolicySetDefinitionName
  scope: managementGroup()
  properties: {
    description: 'Deploy Cloud Adoption Framework Governance Policies'
    displayName: 'Cloud Adoption Framework Foundation Policies'
    policyDefinitions: [
      {
        policyDefinitionId: resourceGroupLocationPolicyDefinitionId
        policyDefinitionReferenceId: resourceGroupLocationPolicyAssignmentName
        parameters: {
          listOfAllowedLocations: {
            value: allowedLocations
          }
        }
      }
      {
        policyDefinitionId: resourceLocationPolicyDefinitionId
        policyDefinitionReferenceId: resourceLocationPolicyAssignmentName
        parameters: {
          listOfAllowedLocations: {
            value: allowedLocations
          }
        }
      }
      {
        policyDefinitionId: notAllowedResourceTypesPolicyDefinitionId
        policyDefinitionReferenceId: notAllowedResourceTypesPolicyAssignmentName
        parameters: {
          listOfResourceTypesNotAllowed: {
            value: notAllowedResources
          }
        }
      }
      {
        policyDefinitionId: deployNetworkWatcherPolicyDefinitionId
        policyDefinitionReferenceId: deployNetworkWatcherPolicyAssignmentName
      }
      {
        policyDefinitionId: storageAccountSecureTransferEnabledPolicyPolicyDefinitionId
        policyDefinitionReferenceId: storageAccountSecureTransferEnabledPolicyAssignmentName
        parameters: {
          effect: {
            value: 'Audit'
          }
        }
      }
      {
        policyDefinitionId: allowedStorageAccountSkuPolicyDefinitionId
        policyDefinitionReferenceId: allowedStorageAccountSkuPolicyAssignmentName
        parameters: {
          listOfAllowedSKUs: {
            value: allowedStorageSku
          }
        }
      }
      {
        policyDefinitionId: allowedVmSkuPolicyDefinitionId
        policyDefinitionReferenceId: allowedVmSkuPolicyAssignmentName
        parameters: {
          listOfAllowedSKUs: {
            value: allowedVMSku
          }
        }
      }
    ]
  }
}
