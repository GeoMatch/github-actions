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
}

variable "public_subnets" {
  type        = list(any)
  description = "List of public subnets."

  validation {
    condition     = length(var.public_subnets) == 3
    error_message = "Must have three public subnets."
  }
}

variable "private_subnets" {
  type        = list(any)
  description = "List of private subnets"

  validation {
    condition     = length(var.private_subnets) == 3
    error_message = "Must have three private subnets."
  }
}
