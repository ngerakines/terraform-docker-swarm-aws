variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}

variable "vpc_key" {
  description = "A unique identifier for the VPC."
  default     = "nickg"
}

variable "cluster_manager_count" {
    description = "Number of manager instances for the cluster."
    default = 1
}

variable "cluster_node_count" {
    description = "Number of node instances for the cluster."
    default = 3
}
