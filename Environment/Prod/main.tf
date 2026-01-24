##resource_group_name##
module "resource_group" {
  source = "../../Modules/resource_group"

  rgs = {
    prod_rg = {
      name     = "${var.environment}-rg"
      location = "australiaeast"
      tags     = {
        environment = "Production"
        owner       = "DevOpsTeam"
      }
    }
  }

}

####vnet####

module "virtual_network" {
  source = "../../Modules/virtual_network"

  vnets = {
    prod_vnet = {
      name                = "${var.environment}-vnet"
      address_space       = ["10.0.0.0/16"]
      location            = module.resource_group.rg_locations[local.rg_key]
      resource_group_name = module.resource_group.rg_names[local.rg_key]
      tags = {
        environment = "Production"
        owner       = "NetworkTeam"
      }
    }
  }

nsgs = {
    prod_nsg = {
      name                 = "${var.environment}-nsg"
      location             = module.resource_group.rg_locations[local.rg_key]
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      tags = {
        environment = "Production"
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
    prod_subnet_frontend = {
      name                 = "${var.environment}-frontend_subnet"
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      virtual_network_name = module.virtual_network.vnet_names["prod_vnet"]
      address_prefixes     = ["10.0.0.0/24"]

}

   prod_subnet_backend = {
      name                 = "${var.environment}-backend_subnet"
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      virtual_network_name = module.virtual_network.vnet_names["prod_vnet"]
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
    prod_kv = {
      name                 = "${var.environment}-jagseerkv"
      location             = module.resource_group.rg_locations[local.rg_key]
      resource_group_name  = module.resource_group.rg_names[local.rg_key]
      sku_name             = "standard"
      soft_delete_retention_days  = 7
      purge_protection_enabled    = false
      enabled_for_disk_encryption = false
      access_policies      = []
      tags = {
        environment = "Production"
        owner       = "SecurityTeam"
      }
    }
  }

  kv_rbac_assignments = {
    prod_kv_reader = {
      kv_name     = "prod_kv"
      role        = "Key Vault Secrets Officer"
  
}
  }

  kv_secrets = {
    prod_db_password = {
      name         = "db-password"
      value        = random_password.secrets["db"].result
      kv_key       = "prod_kv"
      content_type = "text/plain"
      tags = {
        environment = "Production"
        owner       = "DBATeam"
      }
    }

    prod_frontend_vm_password = {
      name         = "frontend-vm-password"
      value        = random_password.secrets["frontend_vm"].result
      kv_key       = "prod_kv"
      content_type = "text/plain"
      tags = {
        environment = "Production"
        owner       = "AppTeam"
      }
    }

    prod_backend_vm_password = {
      name         = "backend-vm-password"
      value        = random_password.secrets["backend_vm"].result
      kv_key       = "prod_kv"
      content_type = "text/plain"
      tags = {
        environment = "Production"
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
      location            = module.resource_group.rg_locations["prod_rg"]
      resource_group_name = module.resource_group.rg_names["prod_rg"]
      allocation_method   = "Dynamic"
      sku                 = "Basic"
    }
  }

  nics = {
    frontend_nic = {
      name                 = "frontend-nic"
      location             = module.resource_group.rg_locations["prod_rg"]
      resource_group_name  = module.resource_group.rg_names["prod_rg"]
      public_ip_key  = "frontend_pip"
     
      network_security_group_key        = "prod_nsg"

      ip_configuration = {
        name = "ipconfig1"
        private_ip_address_allocation = "Dynamic"
         subnet_id     = module.virtual_network.subnet_ids["prod_subnet_frontend"]
      
      }
    }

    backend_nic = {
      name                 = "backend-nic"
      location             = module.resource_group.rg_locations["prod_rg"]
      resource_group_name  = module.resource_group.rg_names["prod_rg"]
      public_ip_key  = null
      network_security_group_key        = "prod_nsg"
       ip_configuration = {
        name = "ipconfig1"
        private_ip_address_allocation = "Dynamic"
        subnet_id    = module.virtual_network.subnet_ids["prod_subnet_backend"]
        
      }
    }
  }

  vms = {
    frontend_vm = {
      name                = "frontend-vm"
      location            = module.resource_group.rg_locations["prod_rg"]
      resource_group_name = module.resource_group.rg_names["prod_rg"]
      size                = "Standard_B1s"
      nic_keys = ["frontend_nic"]

      admin_username = "azureuser"
      admin_password = module.kv.kv_secret_values["prod_frontend_vm_password"]


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
      location            = module.resource_group.rg_locations["prod_rg"]
      resource_group_name = module.resource_group.rg_names["prod_rg"]
      size                = "Standard_B1s"
      nic_keys = ["backend_nic"]

      admin_username = "azureuser"
      admin_password = module.kv.kv_secret_values["prod_backend_vm_password"]


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
    prod_sql_server = {
      name                       = "${var.environment}-jagseer-sqlserver"
      resource_group_name        = module.resource_group.rg_names["prod_rg"]
      location                   = module.resource_group.rg_locations["prod_rg"]
      version                    = "12.0"
      administrator_login        = "sqladminuser"
      administrator_login_password = module.kv.kv_secret_values["prod_db_password"]
    }
  }

  sql_databases = {
    prod_sqldb = {
      name          = "${var.environment}-sqldb"
      server_key   = "prod_sql_server"
      sku_name     = "S0"
      max_size_gb  = 10
      collation    = "SQL_Latin1_General_CP1_CI_AS"
      zone_redundant = false
      read_scale   = false
    }
  }
  
}