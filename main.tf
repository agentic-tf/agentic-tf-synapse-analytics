locals {
  # Strip non-alphanumeric, take first 11 chars, append pool suffix (max 15 chars)
  name_clean = substr(replace(var.name, "/[^a-z0-9]/", ""), 0, 11)
  private_dns_zone_ids = var.create_private_dns_zones ? {
    Sql = azurerm_private_dns_zone.synapse[0].id
  } : var.private_dns_zone_ids
}

# ── ADLS Gen2 filesystem (created by module when storage_account_id provided) ─
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  count              = var.storage_account_id != "" ? 1 : 0
  name               = "synapse"
  storage_account_id = var.storage_account_id
}

# ── SQL admin password ────────────────────────────────────────────────
resource "random_password" "synapse_sql" {
  count   = var.generate_sql_password ? 1 : 0
  length  = 24
  special = true
}

# ── Synapse Workspace ────────────────────────────────────────────────
resource "azurerm_synapse_workspace" "this" {
  name                                 = var.name
  resource_group_name                  = var.resource_group_name
  location                             = var.location
  storage_data_lake_gen2_filesystem_id = var.storage_account_id != "" ? azurerm_storage_data_lake_gen2_filesystem.synapse[0].id : var.adls_filesystem_id
  sql_administrator_login              = var.sql_administrator_login
  sql_administrator_login_password     = var.generate_sql_password ? random_password.synapse_sql[0].result : var.sql_administrator_login_password
  tags                                 = var.tags

  # ── Security hardening ──────────────────────────────────────────────
  # I.AZR.0257 / I.AZR.0033 — no public access (non-negotiable)
  public_network_access_enabled = false

  # Managed VNet — isolate data exfiltration paths
  managed_virtual_network_enabled = true

  # I.AZR.0249 — Entra ID only authentication for workspace SQL access
  azuread_authentication_only = true

  # I.AZR.0019 — Managed Identity
  identity {
    type = "SystemAssigned"
  }
}

# ── Lock down storage after workspace creation ────────────────────────
# The ADLS filesystem creation and Synapse workspace linking both require
# data-plane access. Network rules are applied only after the workspace
# is fully created to avoid race conditions.
resource "azurerm_storage_account_network_rules" "synapse_lockdown" {
  count              = var.storage_account_id != "" ? 1 : 0
  storage_account_id = var.storage_account_id
  default_action     = "Deny"
  bypass             = ["AzureServices"]
  ip_rules           = []

  depends_on = [azurerm_synapse_workspace.this]
}

# ── AAD Admin (I.AZR.0249) — conditional on object_id being provided ──
resource "azurerm_synapse_workspace_sql_aad_admin" "this" {
  count                = var.aad_admin_object_id != "" ? 1 : 0
  synapse_workspace_id = azurerm_synapse_workspace.this.id
  login                = var.aad_admin_login
  object_id            = var.aad_admin_object_id
  tenant_id            = var.aad_admin_tenant_id
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

  # I.AZR.0116 — Transparent data encryption on by default in Azure;
  # data_encrypted attribute defaults to true for new pools.
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

# ── Microsoft Defender for SQL (I.AZR.0629) ──────────────────────────
resource "azurerm_synapse_workspace_security_alert_policy" "this" {
  synapse_workspace_id         = azurerm_synapse_workspace.this.id
  policy_state                 = "Enabled"
  disabled_alerts              = []
  email_account_admins_enabled = true
}

# ── Private Endpoint ──────────────────────────────────────────────────
resource "azurerm_private_endpoint" "synapse" {
  name                = "${var.name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.name}-psc"
    private_connection_resource_id = azurerm_synapse_workspace.this.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = contains(keys(local.private_dns_zone_ids), "Sql") ? [1] : []
    content {
      name                 = "synapse-dns-group"
      private_dns_zone_ids = [local.private_dns_zone_ids["Sql"]]
    }
  }

  tags = var.tags
}

# ── Private DNS Zone ──────────────────────────────────────────────────
resource "azurerm_private_dns_zone" "synapse" {
  count               = var.create_private_dns_zones ? 1 : 0
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "synapse" {
  count                 = var.create_private_dns_zones ? 1 : 0
  name                  = "${var.name}-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.synapse[0].name
  virtual_network_id    = var.virtual_network_id
  registration_enabled  = false
  tags                  = var.tags
}

# ── Diagnostic Settings (I.AZR.0013) ─────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "synapse" {
  count = var.log_analytics_workspace_id != "" ? 1 : 0

  name                       = "${var.name}-diag"
  target_resource_id         = azurerm_synapse_workspace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "SynapseRbacOperations"
  }

  enabled_log {
    category = "GatewayApiRequests"
  }

  enabled_log {
    category = "BuiltinSqlReqsEnded"
  }

  enabled_log {
    category = "IntegrationPipelineRuns"
  }

  enabled_log {
    category = "IntegrationActivityRuns"
  }

  enabled_log {
    category = "IntegrationTriggerRuns"
  }

  metric {
    category = "AllMetrics"
  }
}
