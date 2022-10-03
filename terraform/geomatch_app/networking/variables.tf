variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

# ---- OPTIONALS ----

variable "vpc_cidr_block" {
  type        = string
  description = "The CIDR block for the VPC."
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = list(any)
  description = "List of public subnets."
  default     = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]

  validation {
    condition     = length(var.public_subnets) == 3
    error_message = "Must have three public subnets."
  }
}

variable "private_subnets" {
  type        = list(any)
  description = "List of private subnets"
  default     = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]

  validation {
    condition     = length(var.private_subnets) == 3
    error_message = "Must have three private subnets."
  }
}
