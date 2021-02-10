resource "azurerm_resource_group" "appgw_rg" {
  count    = length(local.locations)
  name     = "${var.prefix}-appgw${count.index + 1}-rg"
  location = element(local.locations, count.index)
}

resource "azurerm_public_ip" "appgw" {
  count               = length(local.locations)
  name                = "${var.prefix}-appgw${count.index + 1}-pip"
  resource_group_name = element(azurerm_resource_group.appgw_rg.*, count.index).name
  location            = element(local.locations, count.index)
  allocation_method   = "Dynamic"
}

locals {
  frontend_ip_configuration_name = "public"
}

resource "azurerm_application_gateway" "appgw" {
  count               = length(local.locations)
  name                = "${var.prefix}-appgw${count.index + 1}"
  resource_group_name = element(azurerm_resource_group.appgw_rg.*, count.index).name
  location            = element(local.locations, count.index)
  zones               = [1, 2, 3]
  enable_http2        = true

  sku {
    name     = "Standard_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 5
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  gateway_ip_configuration {
    name      = "ip-configuration"
    subnet_id = element(azurerm_subnet.appgw.*, count.index).id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = element(azurerm_public_ip.appgw.*, count.index).id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  http_listener {
    name                           = "https"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = "https"
    protocol                       = "Https"
  }

  backend_address_pool {
    name         = "notejam-backend"
    ip_addresses = [cidrhost(element(azurerm_subnet.k8s.*, count.index).address_prefixes[0], 20)]
  }

  backend_http_settings {
    name                  = "notejam-backend-http-settings"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
  }

  request_routing_rule {
    name                       = "notejam"
    rule_type                  = "Basic"
    http_listener_name         = "http"
    backend_address_pool_name  = "notejam-backend"
    backend_http_settings_name = "notejam-backend-http-settings"
  }
}

data "azurerm_monitor_diagnostic_categories" "appgw" {
  count       = length(local.locations)
  resource_id = element(azurerm_application_gateway.appgw, count.index).id
}

resource "azurerm_monitor_diagnostic_setting" "appgw" {
  count                      = length(local.locations)
  name                       = "appgw${count.index + 1}-to-log-analytics"
  target_resource_id         = element(azurerm_application_gateway.appgw, count.index).id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  dynamic "log" {
    for_each = element(data.azurerm_monitor_diagnostic_categories.appgw, count.index).logs

    content {
      category = log
      enabled  = true
    }
  }

  metric {
    category = "AllMetrics"
  }
}