resource "aws_security_group" "public_wordpress_db" {
  name = "${var.env}-public-wordpress-db"
  description = "A security group for for database of wordpresss in ${var.env} environment"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.public_wordpress.id}",
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

output "sg_public_wordpress_db_id" {
	value = "${aws_security_group.public_wordpress_db.id}"
}