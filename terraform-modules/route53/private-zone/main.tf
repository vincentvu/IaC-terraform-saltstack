resource "aws_route53_zone" "private_zone" {
  name = "${var.name}"
  vpc_id = "${var.vpc_id}"

  tags {
    Environment = "${var.env}"
  }
}
