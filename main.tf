locals {
  # Strip non-alphanumeric, take first 11 chars, append pool suffix (max 15 chars)
  name_clean = substr(replace(var.name, "/[^a-z0-9]/", ""), 0, 11)
}

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

# Dedicated SQL Pool — for data analytics (DW queries)
resource "azurerm_synapse_sql_pool" "this" {
  count                = var.enable_sql_pool ? 1 : 0
  name                 = "${local.name_clean}sql"
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  sku_name             = var.sql_pool_sku
  create_mode          = "Default"
  storage_account_type = "GRS"
  tags                 = var.tags
}

# Spark Pool — for data engineering (ETL/ELT)
resource "azurerm_synapse_spark_pool" "this" {
  count                = var.enable_spark_pool ? 1 : 0
  name                 = "${local.name_clean}spk"
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  node_size_family     = "MemoryOptimized"
  node_size            = var.spark_node_size
  spark_version        = "3.4"
  tags                 = var.tags

  auto_scale {
    min_node_count = var.spark_executors_min
    max_node_count = var.spark_executors_max
  }

  auto_pause {
    delay_in_minutes = var.spark_pause_delay_min
  }
}
