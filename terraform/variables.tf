variable "project" {
  type        = string
  description = "Project tag for every resource"
}

variable "aws_region" {
  type        = string
  description = "Region for all resources dependant on the IAM"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g. 10.0.0.0/16."
  }
}

variable "azs" {
  type        = list(string)
  description = "Availability zones; the ALB requires at least two"

  validation {
    # Necessry for the LB / HA
    condition     = length(var.azs) >= 2
    error_message = "At least two AZs are required or CreateLoadBalancer fails."
  }
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "One public subnet CIDR per AZ; holds the ALB, bastion and NAT"

  validation {
    # 1 AZ == 1 SubNet
    condition     = length(var.public_subnet_cidrs) == length(var.azs)
    error_message = "public_subnet_cidrs must have exactly one entry per AZ."
  }
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "One private subnet CIDR per AZ; holds the frontend and backend VMs"

  validation {
    # # 1 AZ == 1 SubNet
    condition     = length(var.private_subnet_cidrs) == length(var.azs)
    error_message = "private_subnet_cidrs must have exactly one entry per AZ."
  }
}

variable "instance_type" {
  type        = string
  description = "Instance type for all VMs"
  # Base nano, might need micro for any relevant code
  default = "t3.nano"

  validation {
    # Should change for real prod builds but don't need more for our current use 
    condition     = contains(["t3.nano", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Only t3.nano, t3.micro or t3.small are allowed (cost fuse)."
  }
}

# Should be empty before the first run
variable "ami_id" {
  type        = string
  description = "AMI to use; empty means look up the latest Amazon Linux 2023"
  default     = ""

  validation {
    condition     = var.ami_id == "" || can(regex("^ami-[0-9a-f]{8,17}$", var.ami_id))
    error_message = "ami_id must be empty or a valid ami-xxxxxxxx identifier."
  }
}

variable "frontend_count" {
  type        = number
  description = "Number of frontend VMs behind the ALB"
  default     = 2

  validation {
    # Just in case ...
    condition     = var.frontend_count >= 1 && var.frontend_count <= 4
    error_message = "frontend_count must be between 1 and 4."
  }
}

variable "backend_count" {
  type        = number
  description = "Number of backend VMs"
  default     = 2

  validation {
    # Just in case ...
    condition     = var.backend_count >= 1
    error_message = "backend_count must be between 1 and 4."
  }
}

variable "key_name" {
  type        = string
  description = "Name of the EC2 key pair object in AWS"
  default     = "iac-final"
}

variable "ssh_public_key_path" {
  type        = string
  description = "Path to the SSH public key, as seen from inside the container"
  default     = "/home/iac/.ssh/id_iac.pub"
}

variable "admin_cidr" {
  type        = string
  description = "Single source allowed to SSH the bastion; your public IP as /32"
  nullable    = false

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid CIDR and must not be 0.0.0.0/0."
  }
}