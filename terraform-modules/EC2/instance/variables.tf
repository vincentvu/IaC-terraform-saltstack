variable "region" {
  default = "us-east-1"
}

variable "roles" {
  description = "Functional roles of instance."
}

variable "vpc_id" {
  description = "ID of VPC."
}

variable "env" {
  default = "prod"
  description = "Short ID of environment."
}
variable "name" {
  default = ""
  description = "Name of the instance"
}
variable "subnet_index" {
  default = 0
  description = "An index of subnet to deploy instance in."
}

variable "instance_type" {
  description = "Instance type"
}

variable "ami" {
  description = "AMI"
}

variable "key_name" {
  description = "SSH key deployed during instance provisioning."
}

variable "subnet_ids" {
  type = "list"
  description = "IDs of subnets to deploy instance in."
}

variable "iam_profile" {
  description = "IAM profile name to associate with instance."
}

variable "user_data" {
  description = "A path to a file with user_data"
}

variable "root_volume_size" {
  description = "The size of the root volume in gigabytes"
}

variable "security_group_ids" {
  type = "list"
  description = "ID of security group"
}

variable "associate_public_ip_address" {
  description = "Associate a public ip address with an instance in a VPC."
}

variable "disable_api_termination" {
  default = false
  description = "If true, enables EC2 Instance Termination Protection."
}

variable "ebs_optimized" {
  default = false
  description = "If true, the launched EC2 instance will be EBS-optimized."
}