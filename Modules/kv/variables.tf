###############################
# Key Vaults to create
###############################
variable "kvs" {
  description = "Map of Key Vaults to create"
  type = map(object({
    name                        = string
    location                    = string
    resource_group_name         = string
    sku_name                    = string
    soft_delete_retention_days  = number
    purge_protection_enabled    = bool
    enabled_for_disk_encryption = bool
    tags                        = optional(map(string))
  }))
}

###############################
# RBAC assignments for Key Vaults
###############################
variable "kv_rbac_assignments" {
  description = "List of role assignments for Key Vaults"
  type = map(object({
    kv_name      = string # Key of the KV in 'kvs' map
    role         = string
  }))
}

variable "kv_secrets" {
  type = map(object({
    name         = string
    value        = string
    kv_key       = string
    content_type = optional(string)
    tags         = optional(map(string))
  }))
}