# Bicep Deployment Stacks

## Introduction

During 2024 Azure released the capability to use deployment stacks.  You can see the announcement in the [Azure blog post](https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/arm-deployment-stacks-now-ga/4145469).

Deployment stacks are an Azure resource of type ```Microsoft.Resources/deploymentStacks``` which enable management of a group of other Azure resources as a single unit.  The aim of this is to improve the resource management lifecycle (create, update and delete) across multiple Azure scopes, for example Management Groups, Subscriptions and Resource Groups.  Another great feature of deployment stacks is the ability to add a denyAssignment to the stack to prevent unwanted changes being made. This is configured in the ```DenySettingsMode``` setting.  The options available for this are:

**DenyDelete** - Adds a denyAssignment that will block all attempted delete operations to managed resources.<br/>
**DenyWriteAndDelete** - Adds a denyAssignment that will block all attempted write and delete operations to managed resources.<br/>
**None** - Disables denyAssignments

There is also the capability to exlcude specified principals from the deny setting with the ```DenySettingsExcludedPrincipal``` and exclude actions with ```DenySettingsExcludedAction```.

However, at the time of writing there are a few limitations and known issues concerning denyAssignments as detailed in the [documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks?tabs=azure-powershell#known-limitations).  More on that later.

The other main configurable capability for deployment stacks is what to do with resources that become "unmanaged".  This is covered by the ```ActionOnUnmanage``` setting.  The options are:

**DeleteResource** - Will delete resources that become unmanaged but will not delete Resource Groups and Management Groups.  They will become detached from the stack.<br/>
**DeleteAll** - Will delete resources, Resource Groups AND Management Groups that become unmanaged.  Obvsiously be VERY CAREFUL with this setting!<br/>
**DetachAll** - Will detach all the resources that become unmanaged but not delete them.

This is a great addition to ease management of complex deployments.  Imagine you had a deployment that spanned multiple Resource Groups in different Azure regions that was regularly deleted and redeployed for maintenance.  That management task will so much easier by using a deployment stack.

## Deployment stacks are perfect for Azure Policy management

So why use deployment stacks to manage Azure Policy?  Policies that need to update something, like deploy an extension to a virtual machine if it is missing, require a system-assigned managed identity or service principal and a role assignment to enable them to carry out the modification.  These policies are of type ```DeployIfNotExists```.  If the policy assignment is removed the system-assigned managed identity is deleted but the role assignment remains.  Resulting in a messy picture in your access control settings, like in the screenshot below:

![Orphaned Role Assignment](https://github.com/paul-mccormack/BicepDeploymentStacks/blob/main/images/orphanedRoleAssignment.jpg)

Deployment Stacks completely cleans this up when you delete the stack.  No more messy unknown guid's lurking around your access control blades!  Hooray!

## Deployment details

This stack will be managing a set of policies originally deployed in my landing zone using Azure Blueprints.  Blueprints is being deprecated on July 11th 2026 with the recommended replacement being deployment stacks.  So I'm staying well ahead of the curve with this one.  The policies are the [CAF Foundation policies](https://learn.microsoft.com/en-us/azure/governance/blueprints/samples/caf-foundation/), I have chosen to split out the resource tagging policy into it's own Bicep template to enhance flexibility around updating it seperately and reusing the template.  I am also applying the guest configuration policiy to ensure all IaaS VM deployments have the required extension installed automatically to enable use of Azure Machine Configuration.

The CAF Foundation policies are:<br/>

* Allowed Azure Region for Resources and Resource Groups<br/>
* Allowed Storage Account SKUs<br/>
* Allowed Azure VM SKUs<br/>
* Require Network Watcher to be deployed<br/>
* Require Azure Storage Account Secure transfer Encryption<br/>
* Deny resource types<br/>

The stack will be deployed at the top level Management Group to ensure all current and future subscriptions are covered by the policies.  Unfortunately this is where one of the deny assignment limitations has an effect.

"Deny-assignments aren't supported at the management group scope. However, they're supported in a management group stack if the deployment is pointed at the subscription scope."

Using ```-DenySettingsMode``` set to ```DenyDelete``` or ```DenyWriteAndDelete``` when deploying to a Management Group scope will error.  I could get round this by by deploying the stack to the Management Group, then targetting the deloyments to each existing Subscription with the ```-DeploymentSubscriptionId``` option. However, that would not meet my requirement of having the policies automatically applied to newly created subscriptions.  Hopefully this limitation will be removed in the future but for now I will have to leave deny assignments out.

The deployment details are in the GitHub actions [workflow](https://github.com/paul-mccormack/BicepDeploymentStacks/blob/main/.github/workflows/policyStack.yml) file.  The options I am using are ```-DenySettingsMode None```, ```ActionOnUnmanage deleteResources``` and ```-Force``` to skip asking for confirmation when overwriting an existing stack.

With the deployment complete we can go to the Management Group in the Azure portal and see what we have done:

![Deployed Stack](https://github.com/paul-mccormack/BicepDeploymentStacks/blob/main/images/deploymentStacks.jpg)

Clicking into one of the stacks will show us the managed resources:

![Managed Resources](https://github.com/paul-mccormack/BicepDeploymentStacks/blob/main/images/managedRoleAssignment.jpg)

The role assignment is listed as a managed resource.  Meaning if this stack is deleted both the Policy assignment and the role assignment will be cleaned up in one action.

It is unfortunate I couldn't make use of a deny assignment. One scenario where they could be useful would be deploying a budget to a Subscription or Resource Group where other users need to have owner access.  The budget could be deployed to the Subscription or Resource Group scope as a stack to a parent Management Group with a deny assignment preventing the resource owner having the ability to remove the budget.  Making deployment stacks a great addition to the Governance toolset.