# Bicep Deployment Stacks

## Introduction

In 2024 Azure released the capability to use deployment stacks.  You can see the announcement in the [Azure blog post](https://techcommunity.microsoft.com/blog/azuregovernanceandmanagementblog/arm-deployment-stacks-now-ga/4145469).

Deployment stacks are an Azure resource of type ```Microsoft.Resources/deploymentStacks``` that enables you to manage a group of other Azure resources as a single atomic unit.  The aim of this resource is to improve the resource management lifecycle (create, update and delete) across multiple Azure scopes, for example Resource Groups, Management Groups and Subscriptions.  Another great feature of deployment stacks is the ability to add a denyAssignment to the stack to prevent unwanted changes being made. This is configured in the ```DenySettingsMode``` setting.  The options available for this are:

DenyDelete - Adds a denyAssignemnt that will block all attempted delete operations to managed resources
DenyWriteAndDelete - Adds a denyAssignment that will block all attempted write and delete operations to managed resources
None - Disables denyAssignments

However at this moment there are a few limitations and known issues concerning denyAssignments as detailed in the [documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-stacks?tabs=azure-powershell#known-limitations).

The other main configurable capability for deployment stacks is what to do with resources that become "unmanaged"?  This is covered by the ```ActionOnUnmanage``` setting.  The options are:

DeleteResource - Will delete resources that become unmanaged but will not delete Resource Groups and Management Groups.  They will become detached from the stack.
DeleteAll - Will delete resources, Resource Groups AND Management Groups that become unmanaged.  Obvsiously be VERY CAREFUL with this setting!
DetatchAll - Will detach all the resources that become unmanaged but not delete them.

This is a great addition to ease management of complex deployment lifecycles.  Imagine you had a deployment that spanned multiple Resource Groups in different Azure regions that was regularly deleted and redeployed for maintenance.  That management task will so much easier if it's completed in a stack.

## Why use deployment stacks to manage Azure Policy

So why use deployment stacks to manage Azure Policy?  Policies that need to update something, like deploy an extension to a virtual machine if it is missing, require a system-assigned managed identity or service principal and a role assignment to enable them to carry out the modification.  These policies are of type ```DeployIfNotExists```.  If the policy assignment is removed the system-assigned managed identity is deleted but the role assignment remains.  Resulting in a messy picture in your IAM settings, like in the screenshot below:

![Orphaned Role Assignment](https://github.com/paul-mccormack/BicepDeploymentStacks/blob/main/images/orphanedRoleAssignment.jpg)

Deployment Stacks completely cleans this up when you delete the stack.  No more messy unknown guid's lurking around your IAM blades!  Hooray!

## Deployment details

