variable "public_subnets" {
  type = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnets" {
  type = list(string)
  default = ["10.1.101.0/24", "10.1.102.0/24"]
}
