# Resource block to generate a random string for the local admin password
resource "random_string" "AVD_local_password" {
  length           = 16
  special          = true
  min_special      = 2
  override_special = "*!@#?"
}

# Resource block to create a network interface for the AVD VM
resource "azurerm_network_interface" "avd_vm_nic" {
  name                          = "${var.prefix}-nic"
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = data.azurerm_resource_group.rg.location
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "nic_config"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    data.azurerm_resource_group.rg
  ]
}

# Resource block to create an MGMT VM
resource "azurerm_windows_virtual_machine" "mgmt_vm" {
  name                       = "vm-mgmt-${var.prefix}"
  resource_group_name        = data.azurerm_resource_group.rg.name
  location                   = data.azurerm_resource_group.rg.location
  size                       = var.vm_size
  license_type               = "Windows_Client"
  network_interface_ids      = ["${azurerm_network_interface.avd_vm_nic.id}"]
  provision_vm_agent         = true
  admin_username             = var.local_admin_username
  admin_password             = var.localpassword
  encryption_at_host_enabled = true //'Microsoft.Compute/EncryptionAtHost' feature is must be enabled in the subscription for this setting to work https://learn.microsoft.com/en-us/azure/virtual-machines/disks-enable-host-based-encryption-portal?tabs=azure-powershell
  secure_boot_enabled        = true
  vtpm_enabled               = true
  os_disk {
    name                 = lower(var.prefix)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  # To use marketplace image, uncomment the following lines and comment the source_image_id line
  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = "latest"
  }
  identity {
    type         = "UserAssigned"
    identity_ids = ["/subscriptions/b0aeeba8-4430-4cf1-acbc-6e24cadf86c9/resourceGroups/rg-avd-eastu-adds-storage/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-avd-fslogix-eus-adds"]
  }

}

# Resource block to join the MGMT VM to a domain
resource "azurerm_virtual_machine_extension" "domain_join" {
  name                       = "${var.prefix}-domainJoin"
  virtual_machine_id         = azurerm_windows_virtual_machine.mgmt_vm.id
  publisher                  = "Microsoft.Compute"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
    {
      "Name": "${var.domain_name}",
      "OUPath": "${var.ou_path}",
      "User": "${var.domain_user}@${var.domain_name}",
      "Restart": "true",
      "Options": "3"
    }
SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
    {
      "Password": "${var.domain_password}"
    }
PROTECTED_SETTINGS

  lifecycle {
    ignore_changes = [settings, protected_settings]
  }
}

resource "azurerm_virtual_machine_extension" "dscStorageScript" {
  name                 = "AzureFilesDomainJoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.mgmt_vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"

  settings = jsonencode({
    fileUris         = [var.baseScriptUri]
    commandToExecute = "powershell.exe -ExecutionPolicy Unrestricted -File ${var.vfile} ${var.scriptArguments} -DomainAdminUserPassword ${var.domainJoinUserPassword} -verbose"
  })

  depends_on = [
    azurerm_virtual_machine_extension.domain_join
  ]
}

/*
# Resource block to install Microsoft Antimalware on the MGMT VM
resource "azurerm_virtual_machine_extension" "mal" {
  name                       = "IaaSAntimalware"
  virtual_machine_id         = azurerm_windows_virtual_machine.mgmt_vm.id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "IaaSAntimalware"
  type_handler_version       = "1.3"
  auto_upgrade_minor_version = "true"

  depends_on = [
    azurerm_virtual_machine_extension.domain_join,
    azurerm_virtual_machine_extension.dsc-stor
  ]
}
*/