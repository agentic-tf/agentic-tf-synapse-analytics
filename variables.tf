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
