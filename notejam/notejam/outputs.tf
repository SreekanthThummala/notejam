output "mssql_resource_group_name" {
  value = azurerm_resource_group.mssql_rg[0].name
}

output "mssql_server_name" {
  value = azurerm_mssql_server.mssql[0].name
}

output "mssql_db_name" {
  value = azurerm_mssql_database.notejam.name
}