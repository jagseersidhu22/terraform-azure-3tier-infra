variable "vnets" {
    type = map(object({
        name          = string
        address_space = list(string)
        location      = string
        resource_group_name = string
        tags = optional(map(string))
    }))
  
}

variable "nsgs" {
  description = "A map of Network Security Groups to create"
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    tags                = map(string)
    security_rules               = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
}

variable "subnets" {
  type = map(object({
    name                 = string
    address_prefixes     = list(string)
    virtual_network_name = string
    resource_group_name  = string
  }))
}
