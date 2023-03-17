resource "azurerm_resource_group" "azure_k8s" {
  location = var.location
  name = local.common_name
  tags = var.tag
}