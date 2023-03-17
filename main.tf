resource "azurerm_resource_group" "azure_k8s" {
  location = var.location
  name = local.common_name
  tags = var.tags
}

resource "random_id" "azure_random" {
   byte_length = 8
}

resource "azurerm_log_analytics_workspace" "azure_workspace" {
   location = var.location
   name = "k8s-workspace-${random_id.azure_random.hex}"
   resource_group_name = azurerm_resource_group.azure_k8s.name
   sku = "PerGB2018"
   retention_in_days = 30

}

resource "azurerm_log_analytics_solution" "azure_logsolution" {
   location = azurerm_resource_group.azure_k8s.location
   resource_group_name = azurerm_resource_group.azure_k8s.name
   solution_name = "ContainerInsights"
   workspace_name = azurerm_log_analytics_workspace.azure_workspace.name
   workspace_resource_id = azurerm_log_analytics_workspace.azure_workspace.id
   plan {
     publisher = "Microsoft"
     product = "OMSGallery/ContainerInsights"
   }
}

resource "azurerm_virtual_network" "vnet" {
   address_space = [element(var.address_space,0)]
   location = var.location
   name = "${local.common_name}-vnet"
   resource_group_name = azurerm_resource_group.azure_k8s.name
  
}

resource "azurerm_subnet" "subnet" {
  address_prefix = element(var.address_space,1)
  name = "${location.common_name}-subnet"
  resource_group_name = azurerm_resource_group.azure_k8s.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "public_ip" {
  location = var.location
  name = "${local.common_name}-public_ip"
  resource_group_name = azurerm_resource_group.azure_k8s.name
}

resource "azurerm_kubernetes_cluster" "k8s_cluster" {
  dns_prefix = var.dns_prefix
  location = var.location
  kubernetes_version = "1.24"
  name = "${local.common_name}-k8scluster"

  resource_group_name = azurerm_resource_group.azure_k8s.name
  default_node_pool {
    name = var.agent_pool
    vm_size = var.agent_pool
    node_count = 2
    availability_zone = ["1","2"]
  }

  service_principal {
    client_id = var.client_id
    client_secret = var.client_secret
  }

  network_profile {
    network_plugin = element(var.network_profile,0)
    load_balancer_sku = element(var.network_profile,2)
    network_policy = element(var.network_profile,0)
  }

  role_based_access_control {
    enabled = true
  }

  addon_profile {
    oms_agent {
      enabled = true
      log_analytics_workspace_id = azurerm_log_analytics_solution.azure_logsolution.id
    }

    kube_dashboard {
      enabled = true
    }

   lifecycle {
     ignore_changes = [
      windows_profile,
        default_node_pool,
     ] 

    } 
      
    tags = var.tags
  }
}