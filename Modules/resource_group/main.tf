###############################
# Resource Groups
###############################
resource "azurerm_resource_group" "rgname" {
  for_each   = var.rgs
  name       = each.value.name
  location   = each.value.location
  managed_by = lookup(each.value, "managed_by", null)
  tags       = lookup(each.value, "tags", null)
}

output "rg_ids" {
  value = { for k, v in azurerm_resource_group.rgname : k => v.id }
}

output "rg_names" {
  value = { for k, v in azurerm_resource_group.rgname : k => v.name }
}
output "rg_locations" {
  value = { for k, v in azurerm_resource_group.rgname : k => v.location }
}
