variable "aws_region" {
  description = "AWS region to deploy the Kubernetes cluster"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "k8s-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_ami" {
  description = "AMI ID for Ubuntu 22.04 (optional - will auto-detect latest if not provided)"
  type        = string
  default     = ""
}

variable "instance_key_pair" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "control_plane_instance_type" {
  description = "Instance type for control plane node"
  type        = string
  default     = "t3.xlarge" # 4G memory, 2 CPUs
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.2xlarge" # 8G memory, 4 CPUs
}

variable "worker_node_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 3
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 40
}
