provider "aws" {
  region = "us-east-1"
}

module "demo-vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc"
  name = "demo"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  cidr = "10.10.0.0/16"
  private_subnets = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets  = ["10.10.101.0/24", "10.10.102.0/24", "10.10.103.0/24"]
  azs      = ["us-east-1a", "us-east-1b", "us-east-1c"]

  tags {
    "Environment" = "demo"
  }
}

module "demo-iam-profiles" {
  source = "../terraform-modules/IAM/iam-profiles"
  env = "demo"
  pillar_bucket = "vincentvu-pillars-demo"
}

module "demo-SGs" {
  source = "../terraform-modules/VPC/SGs"
  vpc_id = "${module.demo-vpc.vpc_id}"
  env = "demo"
}

module "demo-key-pair" {
  source = "../terraform-modules/EC2/key-pair"
  key_name = "demo"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDfSf76KmWIT3TNcxp107zG0LPi1qchhl+bjTYpApu2f2WDeN/dcjpDTSTfWuPUsih8KdQLT9Uw2qkgkherRIF1JU156YuOqAdA5G2uyBT69dF7htl8DSIgiltLxLPv7lI6EnX/aX6LcTDwF8v/wlrOJvWuUkfoAvyyX/fArgR1rE2UbTkQ8Dgn0kdZjHGc0v+GRkr8vP+VyHmXa2mfhJgnthv76xTewhxjYxW4jRZA7Fu5CTBUjjTOBWq2pY22BBwm4ZGw3X3NdSTSFruKLdtemH/8nUZwG0FXbzQf7tUQQ2EvutXCDAnBck3eIerRHyQSY88MapLjB03fd11bgROukXau/3jo8MNt3sdvfeDc3FlTdmth7sEn6czxiwNEGuWf/+c8dY9xK15Fm+WEYpf5ILufcV6aIwY/XZi+7B+xtgsgTrljDYq5TN3aEfKsLm8Qqo3oo680mD5hmlEUilDIqTbpHQnSj9FcmRhXdSve8puMbZHi6cARyQlYPT0Py/81yLSUo/0RwOBrdUwstyRayUG40zIKMqcOmyWOV4AQQbzCScy+v9LcbR1+RmykGd0pg2JR8nOSflaOS1GWTbrhOE+MrU4NkCJ2+A9zQGvYen1rflQ2Lym0iQRLNVn1U/quYq9gC23/Og3DtAzCzeYp6PMyRMPO8VPBxsOC2JsACw== vincent.vu@rubikloud.com"
}

module "demo-wordpress-instance" {
  source = "../terraform-modules/EC2/instance"
  vpc_id = "${module.demo-vpc.vpc_id}"
  env = "demo"
  subnet_ids = "${module.demo-vpc.public_subnets}"
  subnet_index = 0
  ami = "ami-b14ba7a7"
  key_name = "${module.demo-key-pair.key_name}"
  root_volume_size = "20"
  iam_profile = "${module.demo-iam-profiles.iam_profile_wordpress_instance}"
  instance_type = "t2.micro"
  security_group_ids = [ "${module.demo-SGs.sg_public_wordpress_id}" ]
  associate_public_ip_address = "true"
  roles ="wordpress"
  name = "wordpress"
  user_data = "ec2-user-data/demo-user-data.yaml"
}

module "demo-private-dns-zone" {
  source = "../terraform-modules/route53/private-zone"
  env = "demo"
  name = "demo.local"
  vpc_id = "${module.demo-vpc.vpc_id}"
}

module "demo-wordpress-db" {
  source = "../terraform-modules/RDS/mysql"
  vpc_id = "${module.demo-vpc.vpc_id}"
  env = "demo"
  db_name = "wordpress"
  role = "wordpress-demo"
  security_group_ids = [ "${module.demo-SGs.sg_public_wordpress_db_id}" ]
  subnet_ids = [ "${module.demo-vpc.private_subnets}" ]
  engine_version = "5.5.46"
  instance_class = "db.t2.micro"
  allocated_storage = "30"
  master_username = "admin"
  master_password = "Xg4gc30b"
  
  private_zone_id = "${module.demo-private-dns-zone.zone_id}"
  dns_name = "wordpress-db.demo.local"
}

