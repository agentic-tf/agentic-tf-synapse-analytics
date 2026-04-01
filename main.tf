resource "azurerm_synapse_workspace" "this" {
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.adls_filesystem_id
  sql_administrator_login              = "sqladmin"
  sql_administrator_login_password     = var.sql_admin_password
  tags                                 = var.tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "this" {
  name                 = "${var.name}-sqlpool"
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  sku_name             = var.sql_pool_sku
  create_mode          = "Default"
  tags                 = var.tags
}
