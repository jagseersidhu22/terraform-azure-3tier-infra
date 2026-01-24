# SQL Servers
###############################
resource "azurerm_mssql_server" "mssql_server" {
  for_each = var.sql_servers
  name     = each.value.name
  resource_group_name          = each.value.resource_group_name
  location                     = each.value.location
  version                      = each.value.version
  administrator_login          = each.value.administrator_login
  administrator_login_password = each.value.administrator_login_password
  tags                         = lookup(each.value, "tags", null)
}

output "sql_server_ids" {
  value = { for k, v in azurerm_mssql_server.mssql_server : k => v.id }
  sensitive = true
}

###############################
# SQL Databases
###############################
resource "azurerm_mssql_database" "sql_databases" {
  for_each   = var.sql_databases
  server_id  = azurerm_mssql_server.mssql_server[each.value.server_key].id
  name       = each.value.name
  sku_name   = each.value.sku_name
  max_size_gb = each.value.max_size_gb
  collation   = each.value.collation
  zone_redundant = each.value.zone_redundant
  read_scale     = each.value.read_scale
  tags           = lookup(each.value, "tags", null)
}

output "sql_database_ids" {
  value     = { for k, v in azurerm_mssql_database.sql_databases : k => v.id }
  sensitive = true
}
