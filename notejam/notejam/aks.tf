resource "azurerm_resource_group" "aks_rg" {
  count    = length(local.locations)
  name     = "${var.prefix}-aks${count.index + 1}-rg"
  location = element(local.locations, count.index)
}

resource "azurerm_kubernetes_cluster" "aks" {
  count               = length(local.locations)
  name                = "${var.prefix}-aks${count.index + 1}"
  location            = element(local.locations, count.index)
  resource_group_name = element(azurerm_resource_group.aks_rg.*, count.index).name
  dns_prefix          = "notejamaks${count.index + 1}"

  kubernetes_version  = "1.16.9"
  node_resource_group = "${var.prefix}-aks${count.index + 1}-nodes-rg"

  default_node_pool {
    name                 = "default"
    type                 = "VirtualMachineScaleSets"
    enable_auto_scaling  = true
    vm_size              = "Standard_D2_v2"
    orchestrator_version = "1.16.9"
    min_count            = 2
    node_count           = 2
    max_count            = 5
    availability_zones   = [1, 2, 3]
    vnet_subnet_id       = element(azurerm_subnet.k8s.*, count.index).id
  }

  role_based_access_control {
    enabled = true
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "Standard"
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [default_node_pool.0.node_count]
  }
}

data "azurerm_monitor_diagnostic_categories" "aks" {
  count       = length(local.locations)
  resource_id = element(azurerm_kubernetes_cluster.aks, count.index).id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  count                      = length(local.locations)
  name                       = "aks${count.index + 1}-to-log-analytics"
  target_resource_id         = element(azurerm_kubernetes_cluster.aks, count.index).id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  dynamic "log" {
    for_each = element(data.azurerm_monitor_diagnostic_categories.aks, count.index).logs

    content {
      category = log
      enabled  = true
    }
  }

  metric {
    category = "AllMetrics"
  }
}