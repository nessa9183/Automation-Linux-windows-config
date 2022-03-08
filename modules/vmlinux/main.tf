## Resource block to create Linux Availability Set
resource "azurerm_availability_set" "linux_avs" {
  name                         = var.linux_avs_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 5
  tags                         = var.common_tags
}



## Resource block to create Linux Virtual machine
resource "azurerm_linux_virtual_machine" "linux_vm" {
  count                 = var.count_val
  name                  = "${var.vm.name}-vm-${format("%1d", count.index + 1)}"
  resource_group_name   = var.resource_group_name
  location              = var.location
  size                  = var.vm.size
  availability_set_id   = azurerm_availability_set.linux_avs.id
  admin_username        = var.admin_user
  network_interface_ids = [element(azurerm_network_interface.network_interface[*].id, count.index + 1)]
  tags                  = var.common_tags
  

  admin_ssh_key {
    username   = var.admin_user
    public_key = file(var.public_key)
  }

  os_disk {
    name                 = "${var.vm.name}-osdisk-${format("%1d", count.index + 1)}"
    caching              = var.os_disk.caching
    storage_account_type = var.os_disk.account_type
    disk_size_gb         = var.os_disk.disk_size
  }

  boot_diagnostics {
    storage_account_uri = var.boot_diagnostics_storage_endpoint
  }


  source_image_reference {
    publisher = var.os_info.publisher
    offer     = var.os_info.offer
    sku       = var.os_info.sku
    version   = var.os_info.version
  }
}

## Resource block for network interface
resource "azurerm_network_interface" "network_interface" {
  count               = var.count_val
  name                = "${var.vm.name}-nic-${format("%1d", count.index + 1)}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.common_tags


  ip_configuration {
    name                          = "${var.vm.name}-ip-${format("%1d", count.index + 1)}"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = element(azurerm_public_ip.public_ip[*].id, count.index + 1)
    private_ip_address_allocation = "Dynamic"
  }
}

## Resource block for public ip address 
resource "azurerm_public_ip" "public_ip" {
  count               = var.count_val
  name                = "${var.vm.name}-pip-${format("%1d", count.index + 1)}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Dynamic"
  domain_name_label   = "${var.vm.name}-vm-${format("%1d", count.index + 1)}"
  tags                = var.common_tags
}

# Resource block to install Network Watcher Extension on the created VMs
resource "azurerm_virtual_machine_extension" "network_watcher" {
  count                = var.count_val
  name                 = var.extension_properties.name
  virtual_machine_id   = element(azurerm_linux_virtual_machine.linux_vm[*].id, count.index + 1)
  publisher            = var.extension_properties.publisher
  type                 = var.extension_properties.type
  type_handler_version = var.extension_properties.type_handler_version
  tags                 = var.common_tags
  depends_on = [
    azurerm_linux_virtual_machine.linux_vm
  ]
}
