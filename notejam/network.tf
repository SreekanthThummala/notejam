resource "azurerm_resource_group" "network_rg" {
  count    = length(local.locations)
  name     = "${var.prefix}-network${count.index + 1}-rg"
  location = element(local.locations, count.index)
}

resource "azurerm_virtual_network" "vnet" {
  count               = length(local.locations)
  name                = "${var.prefix}-vnet${count.index + 1}"
  resource_group_name = element(azurerm_resource_group.network_rg.*, count.index).name
  location            = element(local.locations, count.index)

  address_space = ["10.0.${count.index}.0/24"]
}

resource "azurerm_subnet" "default" {
  count                = length(local.locations)
  name                 = "default"
  resource_group_name  = element(azurerm_resource_group.network_rg.*, count.index).name
  virtual_network_name = element(azurerm_virtual_network.vnet.*, count.index).name
  address_prefixes     = ["10.0.${count.index}.0/25"]
}

resource "azurerm_subnet" "appgw" {
  count                = length(local.locations)
  name                 = "default"
  resource_group_name  = element(azurerm_resource_group.network_rg.*, count.index).name
  virtual_network_name = element(azurerm_virtual_network.vnet.*, count.index).name
  address_prefixes     = ["10.0.${count.index}.128/27"]
}

resource "azurerm_subnet" "k8s" {
  count                = length(local.locations)
  name                 = "default"
  resource_group_name  = element(azurerm_resource_group.network_rg.*, count.index).name
  virtual_network_name = element(azurerm_virtual_network.vnet.*, count.index).name
  address_prefixes     = ["10.0.${count.index}.160/27"]
}
