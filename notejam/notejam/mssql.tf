resource "azurerm_resource_group" "mssql_rg" {
  count    = length(local.locations)
  name     = "${var.prefix}-mssql${count.index + 1}-rg"
  location = element(local.locations, count.index)
}

resource "random_string" "mssql_admin_password" {
  count   = length(local.locations)
  length  = 16
  special = false
}

resource "azurerm_mssql_server" "mssql" {
  count                        = length(local.locations)
  name                         = "${var.prefix}-mssql${count.index + 1}"
  resource_group_name          = element(azurerm_resource_group.mssql_rg.*, count.index).name
  location                     = element(local.locations, count.index)
  version                      = "12.0"
  administrator_login          = "mssql_admin"
  administrator_login_password = element(random_string.mssql_admin_password.*, count.index).result
}

resource "azurerm_sql_virtual_network_rule" "k8s" {
  count               = length(local.locations)
  name                = "k8s"
  resource_group_name = element(azurerm_resource_group.mssql_rg.*, count.index).name
  server_name         = element(azurerm_mssql_server.mssql.*, count.index).name
  subnet_id           = element(azurerm_subnet.k8s.*, count.index).id
}

// it's currently not possible to change backup retention long- or short term in terraform
// we have to do that manually after deployment with post-deployment.sh script
// (setting retention only works with PowerShell currently)

resource "azurerm_mssql_database" "notejam" {
  name           = "notejam"
  server_id      = azurerm_mssql_server.mssql[0].id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = var.mssql_db_max_size_gb
  sku_name       = var.mssql_db_sku
  zone_redundant = true
}

resource "azurerm_sql_failover_group" "db_failover" {
  name                = "${var.prefix}-notejam-db"
  resource_group_name = azurerm_resource_group.mssql_rg[0].name
  server_name         = azurerm_mssql_server.mssql[0].name
  databases           = [azurerm_mssql_database.notejam.id]

  partner_servers {
    id = azurerm_resource_group.mssql_rg[0].id
  }

  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
}

data "azurerm_monitor_diagnostic_categories" "db" {
  resource_id = azurerm_mssql_database.notejam.id
}

resource "azurerm_monitor_diagnostic_setting" "db" {
  name                       = "db1-to-log-analytics"
  target_resource_id         = azurerm_mssql_database.notejam.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.log_analytics.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.db.logs

    content {
      category = log
      enabled  = true
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.db.metrics

    content {
      category = metric
      enabled  = true
    }
  }
}