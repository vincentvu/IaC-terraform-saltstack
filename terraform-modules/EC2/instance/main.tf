provider "aws" {
  region = "${var.region}"
}

resource "aws_instance" "instance" {
  ami = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${var.key_name}"
  vpc_security_group_ids = [ "${var.security_group_ids}" ]
  subnet_id = "${element(var.subnet_ids, var.subnet_index)}"

  iam_instance_profile = "${var.iam_profile}"
  associate_public_ip_address = "${var.associate_public_ip_address}"
  disable_api_termination = "${var.disable_api_termination}"
  ebs_optimized = "${var.ebs_optimized}"

  root_block_device {
    volume_size = "${var.root_volume_size}"
  }

  tags {
    Name = "${var.env}-${var.name}"
    Environment = "${var.env}"
    Roles = "${var.roles}"
  }

  user_data = "${file(var.user_data)}"
}