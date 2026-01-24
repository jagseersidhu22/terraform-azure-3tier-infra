###############################
# Virtual Network
###############################
resource "azurerm_virtual_network" "vnet" {
  for_each            = var.vnets
  name                = each.value.name
  address_space       = each.value.address_space
  location            = each.value.location
  resource_group_name = each.value.resource_group_name
  tags                = lookup(each.value, "tags", null)
}

output "vnet_ids" {
  value = { for k, v in azurerm_virtual_network.vnet : k => v.id }
}

output "vnet_names" {
  value = { for k, v in azurerm_virtual_network.vnet : k => v.name }
}


###############################
# Network Security Groups
###############################

resource "azurerm_network_security_group" "nsg" {
  for_each            = var.nsgs
  name                 = each.value.name
  location             = each.value.location
  resource_group_name  = each.value.resource_group_name
  tags                 = lookup(each.value, "tags", null)

  dynamic "security_rule" {
    for_each = lookup(each.value, "security_rules", [])
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

output "nsg_ids" {
  value = { for k, v in azurerm_network_security_group.nsg : k => v.id }
}




###############################
# Subnets
###############################
resource "azurerm_subnet" "az_subnet" {
  for_each = var.subnets

  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes
}



output "subnet_ids" {
  value = { for k, v in azurerm_subnet.az_subnet : k => v.id }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg" {
  for_each = {
    for k, v in var.subnets : k => v
    if try(v.nsg_key, null) != null
  }

  subnet_id = azurerm_subnet.az_subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.value.nsg_key].id
}

