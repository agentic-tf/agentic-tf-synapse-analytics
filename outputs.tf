output "id" {
  description = "Synapse workspace ID."
  value       = azurerm_synapse_workspace.this.id
}

output "name" {
  description = "Synapse workspace name."
  value       = azurerm_synapse_workspace.this.name
}

output "connectivity_endpoints" {
  description = "Map of connectivity endpoints for the Synapse workspace."
  value       = azurerm_synapse_workspace.this.connectivity_endpoints
}

output "identity_principal_id" {
  description = "Principal ID of the system-assigned managed identity."
  value       = azurerm_synapse_workspace.this.identity[0].principal_id
}

output "private_endpoint_id" {
  description = "Private endpoint resource ID."
  value       = azurerm_private_endpoint.synapse.id
}

output "sql_pool_id" {
  description = "Dedicated SQL pool resource ID (null if disabled)."
  value       = var.enable_sql_pool ? azurerm_synapse_sql_pool.this[0].id : null
}

output "spark_pool_id" {
  description = "Spark pool resource ID (null if disabled)."
  value       = var.enable_spark_pool ? azurerm_synapse_spark_pool.this[0].id : null
}
