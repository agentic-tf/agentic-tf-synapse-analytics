# ── Identity ──────────────────────────────────────────────────────────
variable "name" {
  type        = string
  description = "Synapse workspace name."
}

variable "location" {
  type        = string
  description = "Azure region."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

# ── Authentication ───────────────────────────────────────────────────
variable "sql_administrator_login" {
  type        = string
  description = "SQL administrator login name for the Synapse workspace."
  default     = "sqladmin"
}

variable "generate_sql_password" {
  type        = bool
  description = "Generate a random SQL admin password. Set false and provide sql_administrator_login_password instead."
  default     = true
}

variable "sql_administrator_login_password" {
  type        = string
  description = "SQL administrator login password. Only used when generate_sql_password = false."
  sensitive   = true
  default     = ""
}

variable "aad_admin_login" {
  type        = string
  description = "Entra ID admin display name for the Synapse workspace (I.AZR.0249). Defaults to 'sqladmin' for sandbox use."
  default     = "sqladmin"
}

variable "aad_admin_object_id" {
  type        = string
  description = "Entra ID admin object ID. Empty string skips AAD admin configuration."
  default     = ""
}

variable "aad_admin_tenant_id" {
  type        = string
  description = "Entra ID tenant ID for AAD admin. Empty string skips AAD admin configuration."
  default     = ""
}

# ── Networking ────────────────────────────────────────────────────────
variable "private_endpoint_subnet_id" {
  type        = string
  description = "Subnet ID for the private endpoint."
}

variable "virtual_network_id" {
  type        = string
  description = "Virtual network ID for private DNS zone link."
}

variable "create_private_dns_zones" {
  type        = bool
  description = "Create private DNS zones for the Synapse private endpoint. Set false if centrally managed."
  default     = true
}

variable "private_dns_zone_ids" {
  type        = map(string)
  description = "Existing private DNS zone IDs keyed by subresource name when create_private_dns_zones = false."
  default     = {}
}

# ── Service-specific ─────────────────────────────────────────────────
variable "adls_filesystem_id" {
  type        = string
  description = "ADLS Gen2 filesystem ID used as the workspace default storage."
}

# --- Dedicated SQL Pool (analytics) ---

variable "enable_sql_pool" {
  type        = bool
  description = "Create a dedicated SQL pool. Enable for analytics workloads."
  default     = true
}

variable "sql_pool_sku" {
  type        = string
  description = "SKU for the dedicated SQL pool (e.g. DW100c)."
  default     = "DW100c"
}

# --- Spark Pool (data engineering) ---

variable "enable_spark_pool" {
  type        = bool
  description = "Create a Spark pool. Enable for data engineering workloads."
  default     = false
}

variable "spark_node_size" {
  type        = string
  description = "Spark pool node size: Small, Medium, Large, XLarge."
  default     = "Small"
  validation {
    condition     = contains(["Small", "Medium", "Large", "XLarge"], var.spark_node_size)
    error_message = "spark_node_size must be Small, Medium, Large, or XLarge."
  }
}

variable "spark_executors_min" {
  type        = number
  description = "Minimum number of Spark executors (auto-scale). Azure minimum is 3."
  default     = 3
}

variable "spark_executors_max" {
  type        = number
  description = "Maximum number of Spark executors (auto-scale)."
  default     = 4
}

variable "spark_pause_delay_min" {
  type        = number
  description = "Minutes of idle time before the Spark pool auto-pauses."
  default     = 15
}

# ── Operational ──────────────────────────────────────────────────────
variable "log_analytics_workspace_id" {
  type        = string
  description = "Log Analytics workspace ID for diagnostic logs. Empty string to skip."
  default     = ""
}

# ── Tags ─────────────────────────────────────────────────────────────
variable "tags" {
  type        = map(string)
  description = "Resource tags."
  default     = {}
}
