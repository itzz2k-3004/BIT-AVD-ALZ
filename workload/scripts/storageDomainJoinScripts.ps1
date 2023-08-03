param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CustomScriptPath,  

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $StorageAccountName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $StorageAccountRG,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $SubscriptionId,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $ClientId,
        
	[Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $ShareName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $CustomOuPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $IdentityServiceProvider,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $AzureCloudEnvironment,
	
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $OUName,

	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[string] $CreateNewOU,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainAdminUserName,
	
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $DomainAdminUserPassword,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $StoragePurpose

)
        
Write-Host "Downloading the customScriptStorage.zip from $CustomScriptPath"
$CustomScriptArhive="customScriptStorage.zip"
$AppName = 'customScriptStorage-'+$StoragePurpose
$Drive = 'C:\Packages'
New-Item -Path $drive -Name $AppName -ItemType Directory -ErrorAction SilentlyContinue

Write-Host "Setting custom Script local path to $LocalPath"
$LocalPath = $Drive+'\customScriptStorage-'+$StoragePurpose
$OutputPath = $LocalPath + '\' + $CustomScriptArhive
Invoke-WebRequest -Uri $CustmoScriptPath -OutFile $OutputPath

Write-Host "Expanding the archive $CustomScriptArhive" 
Expand-Archive -LiteralPath $OutputPath -DestinationPath $Localpath -Force -Verbose

Set-Location -Path $LocalPath

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Module 'PSDscResources' -Force

$CustomScriptCompileCommand="./Configuration.ps1 -StorageAccountName " + $StorageAccountName +  " -StorageAccountRG " + $StorageAccountRG+  " -StoragePurpose " + $StoragePurpose +" -ShareName " + $ShareName + " -SubscriptionId " + $SubscriptionId + " -ClientId " + $ClientId +" -DomainName " + $DomainName + " -IdentityServiceProvider " + $IdentityServiceProvider + " -AzureCloudEnvironment " + $AzureCloudEnvironment + " -CustomOuPath " + $CustomOuPath + " -OUName """ + $OUName + """ -CreateNewOU " + $CreateNewOU + " -DomainAdminUserName " + $DomainAdminUserName + " -DomainAdminUserPassword " + $DomainAdminUserPassword + " -Verbose"

Write-Host "Executing the commmand $CustomScriptCompileCommand" 
Invoke-Expression -Command $CustomScriptCompileCommand

$MofFolder='DomainJoinFileShare'
$MofPath=$LocalPath + '\' + $MofFolder
Write-Host "Generated MOF files here: $MofPath"

Write-Host "Applying MOF files. custom script configuration"
Set-WSManQuickConfig -Force -Verbose
Start-DscConfiguration -Path $MofPath -Wait -Verbose -force

Write-Host "Custom script extension run clean up"
Remove-Item -Path $MofPath -Force -Recurse