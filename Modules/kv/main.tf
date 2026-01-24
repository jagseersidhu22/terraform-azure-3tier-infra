  data "azurerm_client_config" "current" {}

  # Key Vault
  ###############################
  resource "azurerm_key_vault" "azure_kv" {
    for_each                   = var.kvs
    name                        = each.value.name
    location                    = each.value.location
    resource_group_name         = each.value.resource_group_name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    sku_name                    = each.value.sku_name
    soft_delete_retention_days  = each.value.soft_delete_retention_days
    purge_protection_enabled    = each.value.purge_protection_enabled
    enabled_for_disk_encryption = each.value.enabled_for_disk_encryption
    tags                        = lookup(each.value, "tags", null)
    enable_rbac_authorization = true

  
    
  }

  output "kv_ids" {
    value     = { for k, v in azurerm_key_vault.azure_kv : k => v.id }
    sensitive = true
  }

  # RBAC Assignments
  ###############################
  resource "azurerm_role_assignment" "kv_rbac" {
    for_each = var.kv_rbac_assignments

    scope                = azurerm_key_vault.azure_kv[each.value.kv_name].id
    role_definition_name = each.value.role
    principal_id         = data.azurerm_client_config.current.object_id

    depends_on = [azurerm_key_vault.azure_kv]
  }

  resource "time_sleep" "wait_for_rbac" {
  depends_on      = [azurerm_role_assignment.kv_rbac]
  create_duration = "120s"   # Wait 120 seconds
}

  resource "azurerm_key_vault_secret" "key_vault_secrets" {
    for_each    = var.kv_secrets
    name        = each.value.name
    value       = each.value.value
    key_vault_id = azurerm_key_vault.azure_kv[each.value.kv_key].id
    content_type = lookup(each.value, "content_type", null)
    tags         = lookup(each.value, "tags", null)

    depends_on = [ time_sleep.wait_for_rbac ]
  }

  output "secret_ids" {
    value = { for k, v in azurerm_key_vault_secret.key_vault_secrets : k => v.id }
  }

  output "kv_secret_values" {
  description = "Map of Key Vault secret values"
  value = {
    for k, v in azurerm_key_vault_secret.key_vault_secrets :
    k => v.value
  }
  sensitive = true
}

