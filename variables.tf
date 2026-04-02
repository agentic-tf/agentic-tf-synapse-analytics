variable "name" {
  type = string
}
variable "location" {
  type = string
}
variable "resource_group_name" {
  type = string
}
variable "tags" {
  type = map(string)
  default = {}
}
variable "adls_filesystem_id" {
  type = string
}
variable "sql_admin_password" {
  type = string
  sensitive = true
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
  description = "Minimum number of Spark executors (auto-scale)."
  default     = 1
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
