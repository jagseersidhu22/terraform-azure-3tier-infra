##resource_group_name##
module "resource_group" {
  source = "../../Modules/resource_group"

  rgs = {
    preprod_rg = {
      name     = "${var.environment}-rg"
      location = "australiaeast"
      tags     = {
        environment = "preprod"
        owner       = "testingteam"
      }
    }
  }

}

####vnet####

module "virtual_network" {
  source = "../../Modules/virtual_network"

  vnets = {
    preprod_vnet = {
      name                = "${var.environment}-vnet"
      address_space       = ["10.0.0.0/16"]
      location            = module.resource_group.rg_locations[local.rg_key]
      resource_group_name = module.resource_group.rg_names[local.rg_key]
      tags = {
        environment = "preprod"
        owner       = "NetworkTeam"
      }
    }
  }

nsgs = {
    preprod_nsg = {
      name                 = "${var.environment}-nsg"
      location             = module.resource_group.rg_locations[local.rg_key]
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      tags = {
        environment = "preprod"
        owner       = "SecurityTeam"
      }
      security_rules = [
        {
          name                       = "Allow-HTTP"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "Allow-HTTPS"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  }
  subnets = {
    preprod_subnet_frontend = {
      name                 = "${var.environment}-frontend_subnet"
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      virtual_network_name = module.virtual_network.vnet_names["preprod_vnet"]
      address_prefixes     = ["10.0.0.0/24"]

}

   preprod_subnet_backend = {
      name                 = "${var.environment}-backend_subnet"
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      virtual_network_name = module.virtual_network.vnet_names["preprod_vnet"]
      address_prefixes     = ["10.0.1.0/24"]

}
  }

}

resource "random_password" "secrets" {
  for_each = {
    frontend_vm = 16
    backend_vm  = 16
    db          = 16
  }

  length  = each.value
  special = true
}

module "kv" {
  source = "../../Modules/kv"

  kvs = {
    preprod_kv = {
      name                 = "${var.environment}-jagseerkv"
      location             = module.resource_group.rg_locations[local.rg_key]
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      sku_name             = "standard"
      soft_delete_retention_days  = 7
      purge_protection_enabled    = false
      enabled_for_disk_encryption = false
      access_policies      = []
      tags = {
        environment = "preprod"
        owner       = "SecurityTeam"
      }
    }
  }

  kv_rbac_assignments = {
    preprod_kv_reader = {
      kv_name     = "preprod_kv"
      role        = "Key Vault Secrets Officer"
  
}
  }

  kv_secrets = {
    preprod_db_password = {
      name         = "db-password"
      value        = random_password.secrets["db"].result
      kv_key       = "preprod_kv"
      content_type = "text/plain"
      tags = {
        environment = "preprod"
        owner       = "DBATeam"
      }
    }

    preprod_frontend_vm_password = {
      name         = "frontend-vm-password"
      value        = random_password.secrets["frontend_vm"].result
      kv_key       = "preprod_kv"
      content_type = "text/plain"
      tags = {
        environment = "preprod"
        owner       = "AppTeam"
      }
    }

    preprod_backend_vm_password = {
      name         = "backend-vm-password"
      value        = random_password.secrets["backend_vm"].result
      kv_key       = "preprod_kv"
      content_type = "text/plain"
      tags = {
        environment = "preprod"
        owner       = "AppTeam"
      }
    }
  }
}

module "vm" {
  source = "../../Modules/compute_vm"
pips = {
    frontend_pip = {
      name                = "${var.environment}-frontend-pip"
      location            = module.resource_group.rg_locations["preprod_rg"]
      resource_group_name = module.resource_group.rg_names["preprod_rg"]
      allocation_method   = "Dynamic"
      sku                 = "Basic"
    }
  }

  nics = {
    frontend_nic = {
      name                 = "frontend-nic"
      location             = module.resource_group.rg_locations["preprod_rg"]
      resource_group_name  = module.resource_group.rg_names["preprod_rg"]
      public_ip_key  = "frontend_pip"
     
      network_security_group_key        = "preprod_nsg"

      ip_configuration = {
        name = "ipconfig1"
        private_ip_address_allocation = "Dynamic"
         subnet_id     = module.virtual_network.subnet_ids["preprod_subnet_frontend"]
      
      }
    }

    backend_nic = {
      name                 = "backend-nic"
      location             = module.resource_group.rg_locations["preprod_rg"]
      resource_group_name  = module.resource_group.rg_names["preprod_rg"]
      public_ip_key  = null
      network_security_group_key        = "preprod_nsg"
       ip_configuration = {
        name = "ipconfig1"
        private_ip_address_allocation = "Dynamic"
        subnet_id    = module.virtual_network.subnet_ids["preprod_subnet_backend"]
        
      }
    }
  }

  vms = {
    frontend_vm = {
      name                = "frontend-vm"
      location            = module.resource_group.rg_locations["preprod_rg"]
      resource_group_name = module.resource_group.rg_names["preprod_rg"]
      size                = "Standard_B1s"
      nic_keys = ["frontend_nic"]

      admin_username = "azureuser"
      admin_password = module.kv.kv_secret_values["preprod_frontend_vm_password"]


      nic_key = "frontend_nic"

      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }

      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"

      identity = {
        type = "SystemAssigned"
      }
    }

    backend_vm = {
      name                = "backend-vm"
      location            = module.resource_group.rg_locations["preprod_rg"]
      resource_group_name = module.resource_group.rg_names["preprod_rg"]
      size                = "Standard_B1s"
      nic_keys = ["backend_nic"]

      admin_username = "azureuser"
      admin_password = module.kv.kv_secret_values["preprod_backend_vm_password"]


      nic_key = "backend_nic"

      os_disk = {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
      }

      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-focal"
      sku       = "20_04-lts"
      version   = "latest"

      identity = {
        type = "SystemAssigned"
      }
    }
  }
}

module "sql" {
  source = "../../Modules/azurerm_sql"

  sql_servers = {
    preprod_sql_server = {
      name                       = "${var.environment}-jagseer-sqlserver"
      resource_group_name        = module.resource_group.rg_names["preprod_rg"]
      location                   = module.resource_group.rg_locations["preprod_rg"]
      version                    = "12.0"
      administrator_login        = "sqladminuser"
      administrator_login_password = module.kv.kv_secret_values["preprod_db_password"]
    }
  }

  sql_databases = {
    preprod_sqldb = {
      name          = "${var.environment}-sqldb"
      server_key   = "preprod_sql_server"
      sku_name     = "S0"
      max_size_gb  = 10
      collation    = "SQL_Latin1_General_CP1_CI_AS"
      zone_redundant = false
      read_scale   = false
    }
  }
  
}