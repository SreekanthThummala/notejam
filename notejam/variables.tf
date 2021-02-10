variable "prefix" {
  type = string
}

variable "primary_location" {
  type = string
}

variable "secondary_location" {
  type = string
}

variable "mssql_db_sku" {
  type    = string
  default = "BC_Gen5_2"
}

variable "mssql_db_max_size_gb" {
  type    = number
  default = 4
}