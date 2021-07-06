variable "resource_group_name" {
  type        = string
  default     = "TF-Demo-RG"
  description = "The resource group name value is passed here."
}

variable "vnet_name" {
  type        = string
  default     = "TF-VNET1"
  description = "The virtual network name value is passed here."
}

variable "server_name" {
  type        = string
  default     = "ubuntu_server_demo"
  description = "The virtual machine name value is passed here."
}
