using './taggingPolicies.bicep'

//Deployment Location
param location = 'uksouth'

//List of required tags.
param tagNames = [
  'Created By'
  'Cost Centre'
  'Service'
]

