using './deploy.bicep'

param alaWorkspaceResourceId = ''
param applicationNameTag = 'Contoso-App'
param asgResourceId = ''
param avsetResourceId = ''
param customImageDefinitionId = ''
param computeSubscriptionId = ''
param computeRgResourceGroupName = ''
param count = 1
param countIndex = 0
param customNaming = false
param createIntuneEnrollment = false
param configureFslogix = false
param createResourceTags = false
param costCenterTag = 'Contoso-CC'
param diskEncryptionSetResourceId = ''
param departmentTag = 'Contoso-AVD'
param dataClassificationTag = 'Non-business'
param diskZeroTrust = false
param deployMonitoring = false
param deploymentEnvironment = 'Dev'
param deploymentPrefix = 'AVD1'
param domainJoinUserName = 'NoUsername'
param diskType = 'Standard_LRS'
param domainJoinPasswordSecretName = 'domainJoinUserPassword'
param enableAcceleratedNetworking = true
param fslogixStorageAccountName = ''
param fslogixFileShareName = ''
param hostPoolResourceId = ''
param identityDomainName = ''
param subnetResourceId = ''
param location = ''
param sessionHostCustomNamePrefix = 'vmapp1duse2'
param useAvailabilityZones = true
param identityServiceProvider = 'ADDS'
param vmSize = 'Standard_D4ads_v5'
param securityType = 'TrustedLaunch'
param secureBootEnabled = true
param vTpmEnabled = true
param useSharedImage = false
param vmLocalUserName = ''
param keyVaultResourceId = ''
param vmLocalAdminPasswordSecretName = ''
param sessionHostOuPath = ''
param osImage = 'win11_22h2'
param workloadNameTag = 'Contoso-Workload'
param workloadTypeTag = 'Light'
param workloadCriticalityTag = 'Low'
param workloadCriticalityCustomValueTag = 'Contoso-Critical'
param workloadSlaTag = 'Contoso-SLA'
param opsTeamTag = 'workload-admins@Contoso.com'
param ownerTag = 'workload-owner@Contoso.com'
