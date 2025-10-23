variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-2" # Or your preferred region
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "innovatemart-eks-cluster"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"] # Example, adjust as needed for multiple AZs
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets."
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"] # Example, adjust as needed for multiple AZs
}

variable "instance_type" {
  description = "EC2 instance type for EKS worker nodes."
  type        = string
  default     = "t3.medium" # Choose an appropriate instance type
}

variable "desired_size" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}
