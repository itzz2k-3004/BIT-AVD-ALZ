variable "dsc_storage_path"  {
  type        = string
  description = "Path to the DSC script"
  default     = "https://github.com/Azure/avdaccelerator/raw/main/workload/scripts/DSCStorageScripts.zip"
}

variable "azure_cloud_environment" {
  type        = string
  description = "Azure Cloud Environment"
  default     = "AzureCloud"

validation {
  condition = contains(["AzureCloud", "AzureChinaCloud", "AzureGermanCloud", "AzureUSGovernment"], var.azure_cloud_environment)
  error_message = "value must be one of AzureCloud, AzureChinaCloud, AzureGermanCloud, AzureUSGovernment"
}
}

variable "publisher" {
  type        = string
  description = "Publisher of the image"
}
variable "offer" {
  type        = string
  description = "Offer of the image"
}

variable "sku" {
  type        = string
  description = "SKU of the image"
}

variable "domain_name" {
  type        = string
  description = "Name of the domain to join"
}

variable "domain_user" {
  type        = string
  description = "Username for domain join (do not include domain name as this is appended)"
}

variable "domain_password" {
  type        = string
  description = "Password of the user to authenticate with the domain"
  sensitive   = true
}

variable "vm_size" {
  description = "Size of the machine to deploy"
}

variable "ou_path" {
  description = "Distinguished name of the organizational unit for the session host"
}

variable "local_admin_username" {
  type        = string
  description = "local admin username"
}

variable "avdLocation" {
  type        = string
  description = "Location of the AVD deployment"
}
variable "rg_so" {
  type        = string
  description = "Name of the Resource group in which to deploy service objects"
}

variable "rg_stor" {
  type        = string
  description = "Name of the Resource group in which to deploy storage"
}

variable "prefix" {
  type        = string
  description = "Prefix for all resources"
}

variable "vnet" {
  type        = string
  description = "Name of the virtual network"
}

variable "snet" {
  type        = string
  description = "Name of the subnet"
}

variable "rg_network" {
  type        = string
  description = "Name of the network resource group"
}

variable "localpassword" {
  type        = string
  description = "Local admin password"
  sensitive   = true
}

variable "spoke_subscription_id" {
  type        = string
  description = "Subscription ID of the spoke"
}

variable "fsshare" {
  type        = string
  description = "Name of the FSLogix share"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the storage account"
}

variable "storge_account_rg" {
  type        = string
  description = "Name of the storage account resource group"
}

variable "IdentityServiceProvider" {
  type        = string
  description = "Identity Service Provider"
}

variable "clientid" {
  type        = string
  description = "Managed Identity Client ID"
}

variable "location" {
  type        = string
  description = "Location where to deploy compute services."
}

variable "baseScriptUri" {
  type        = string
  description = "Location for the AVD agent installation package."
}

variable "vfile" {
  type = string
}

variable "scriptArguments" {
  type        = string
  description = "Arguments for domain join script."
}

variable "domainJoinUserPassword" {
  type        = string
  description = "Domain join user password."
}
