variable "sql_databases" {
    type = map(object({
        name                 = string
        server_key          = string
        sku_name            = string
        max_size_gb        = number
        collation          = string
        zone_redundant     = bool
        read_scale         = bool
        tags               = optional(map(string))
    }))
}

variable "sql_servers" {
  type = map(object({
    name               = string
    resource_group_name = string
    location           = string
    version            = string
    administrator_login = string
  administrator_login_password = string
    tags               = optional(map(string))
  }))
}
