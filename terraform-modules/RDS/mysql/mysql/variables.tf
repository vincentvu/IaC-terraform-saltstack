variable "region" {}

variable "vpc_id" {
  description = "ID of VPC."
}

variable "security_group_id" {
  type = "list"
  description = "Id of RDS security group."
}

variable "env" {
  default = "prod"
  description = "Short ID of environment"
}

variable "subnet_ids" {
  type = "list"
  description = "IDs of subnets to deploy instance in."
}

variable "engine" {
  default = "mysql"
  description = "DB engine of RDS instance."
}

variable "engine_version" {
  default = "9.4.5"
  description = "DB engine version of RDS instance."
}

variable "instance_class" {
  default = "db.t2.micro"
  description = "RDS instance class."
}

variable "allocated_storage" {
  default = 30
  description = "Allocated storage for RDS DB in GB. Minimum: 100 GB, Maximum: 6144 GB."
}

variable "storage_type" {
  default = "gp2"
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), or 'io1' (provisioned IOPS SSD)."
}

variable "maintenance_window" {
  default = "sat:03:27-sat:03:57"
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi'."
}

variable "backup_window" {
  default = "14:17-14:47"
  description = "The window to perform daily backups."
}

variable "backup_retention_period" {
  default = 1
  description = "The days to retain backups for."
}

variable "publicly_accessible" {
  default = false
  description = "Bool to control if instance is publicly accessible."
}

variable "multi_az" {
  default = false
  description = "Specifies if the RDS instance is multi-AZ."
}

variable "port" {
  default = 3306
  description = "The port on which the DB accepts connections."
}

variable "master_username" {
  description = "Username for the master DB user."
}

variable "master_password" {
  description = "Password for the master DB user. May show up in logs, and it will be stored in the state file."
}

variable "snapshot_id" {
  default = ""
  description = "ID of snapshot to create RDS instance from."
}

variable "final_snapshot_identifier" {
  default = ""
  description = "Final snapshot ID."
}

variable "db_name" {
  description = "The Oracle System ID (SID) of the created DB instance."
}

variable "role" {
  description = "Functional role of DB instance."
}

// Variables for DNS
variable "private_zone_id" {}
variable "dns_name" {}

