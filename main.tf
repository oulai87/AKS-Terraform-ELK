resource "azurerm_resource_group" "azure_k8s" {
  location = var.location
  name = local.common_name
  tags = var.tag
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

