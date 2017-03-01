resource "aws_security_group" "public_wordpress" {
  name = "${var.env}-public_wordpress"
  description = "A security group for public wordpresss in ${var.env} environment"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  tags {
    Environment = "${var.env}"
    Name = "${var.env}-public-wordpress"
  }
}

output "sg_public_wordpress_id" {
	value = "${aws_security_group.public_wordpress.id}"
}