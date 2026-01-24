# Network Interfaces
###############################
resource "azurerm_network_interface" "nic" {
  for_each            = var.nics
  name                 = each.value.name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name

  ip_configuration {
    name                          = each.value.ip_configuration.name
    subnet_id                     = each.value.ip_configuration.subnet_id
    private_ip_address_allocation = each.value.ip_configuration.private_ip_address_allocation
    public_ip_address_id          = try(
    azurerm_public_ip.pip[each.value.public_ip_key].id,
    null)
  }

  tags = lookup(each.value, "tags", null)
}

output "nic_ids" {
  value = { for k, v in azurerm_network_interface.nic : k => v.id }
}


# Public IPs
###############################
resource "azurerm_public_ip" "pip" {
  for_each            = var.pips
  name                 = each.value.name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  allocation_method    = each.value.allocation_method
  sku                  = each.value.sku
  tags                 = lookup(each.value, "tags", null)
}

output "pip_ids" {
  value = { for k, v in azurerm_public_ip.pip : k => v.id }
}


# Virtual Machines
###############################
resource "azurerm_linux_virtual_machine" "linux_vm" {
  for_each              = var.vms
  name                  = each.value.name
  location              = each.value.location
  resource_group_name   = each.value.resource_group_name
  size                  = each.value.size
  admin_username        = each.value.admin_username
  admin_password        = each.value.admin_password
  disable_password_authentication = false
 network_interface_ids = [
  for key in each.value.nic_keys :
  azurerm_network_interface.nic[key].id
]



  os_disk {
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
  }

  source_image_reference {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    version   = each.value.version
  }

  identity {
    type = each.value.identity.type
  }

  tags = lookup(each.value, "tags", null)
}

###############################
# OUTPUTS
###############################
output "vm_ids" {
  value = { for k, v in azurerm_linux_virtual_machine.linux_vm : k => v.id }
}

output "vm_principal_ids" {
  value = {
    for k, v in azurerm_linux_virtual_machine.linux_vm :
    k => try(v.identity[0].principal_id, null)
  }
}