
variable "region" {
  type = string
}

variable "vpc_name" {
  type = list(any)
}

variable "public_cidr_block" {
  type = string
}

variable "private_cidr_block" {
  type = string
}

variable "public_subnet_name" {
  type = string
}

variable "private_subnet_name" {
  type = string
}

variable "route_table_name" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "key_name" {
  type = string
}

variable "web_instance_name" {
  type = string
}

variable "streamer_instance_name" {
  type = string
}

variable "web_instance_type" {
  type = string
}

variable "streamer_instance_type" {
  type = string
}

variable "ami_name" {
  type = string
}
