output "id"   { value = azurerm_synapse_workspace.this.id }
output "name" { value = azurerm_synapse_workspace.this.name }

output "sql_pool_id" {
  value = var.enable_sql_pool ? azurerm_synapse_sql_pool.this[0].id : null
}

output "spark_pool_id" {
  value = var.enable_spark_pool ? azurerm_synapse_spark_pool.this[0].id : null
}
