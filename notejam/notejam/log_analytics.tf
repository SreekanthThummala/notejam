resource "azurerm_resource_group" "log_analytics_rg" { 
  name     = "${var.prefix}-log-analytics-rg"
  location = var.primary_location
}

resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "${var.prefix}-loganalytics"
  location            = var.primary_location
  resource_group_name = azurerm_resource_group.log_analytics_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}