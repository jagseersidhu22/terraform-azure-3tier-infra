variable "vms" {
  description = "Map of Linux virtual machines to create"
  type = map(object({
    name                  = string
    location              = string
    resource_group_name   = string
    size                  = string

    admin_username        = string
    admin_password        = string

    nic_keys = list(string)

    os_disk = object({
      caching              = string
      storage_account_type = string
    })

    publisher = string
    offer     = string
    sku       = string
    version   = string

    identity = object({
      type = string # SystemAssigned or UserAssigned
    })

    tags = optional(map(string))
  }))
}


variable "nics" {
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string          # Key of the subnet from module.subnet.subnet_ids
    network_security_group_key = string   # Key of the NSG
    tags                = optional(map(string))
    public_ip_address_id          = optional(string)
    ip_configuration    = object({
      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = string
      public_ip_address_id          = optional(string)
    })
  }))
}

variable "pips" {
  type = map(object({
    name                = string
    location            = string
    resource_group_name = string
    allocation_method   = string
    sku                 = string
    tags = optional(map(string))
  }))
}


