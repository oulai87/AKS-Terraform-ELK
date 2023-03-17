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
}