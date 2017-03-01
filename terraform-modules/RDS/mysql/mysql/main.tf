resource "aws_db_subnet_group" "mysql" {
  name = "${var.env}-${var.engine}-${lower(var.db_name)}"
  subnet_ids = ["${var.subnet_ids}"]
}

resource "aws_db_instance" "mysql" {
  identifier = "${var.env}-${lower(var.db_name)}"
  name = "${var.db_name}"

  engine = "${var.engine}"
  engine_version = "${var.engine_version}"
  instance_class = "${var.instance_class}"
  storage_type = "${var.storage_type}"
  allocated_storage = "${var.allocated_storage}"
  publicly_accessible = "${var.publicly_accessible}"

  username = "${var.master_username}"
  password = "${var.master_password}"

  port = "${var.port}"
  multi_az = "${var.multi_az}"

  snapshot_identifier = "${var.snapshot_id}"
  maintenance_window = "${var.maintenance_window}"
  backup_window = "${var.backup_window}"
  backup_retention_period  = "${var.backup_retention_period}"

  db_subnet_group_name = "${aws_db_subnet_group.mysql.id}"
  vpc_security_group_ids = [ "${var.security_group_ids}" ]

  tags {
    Environment = "${var.env}"
    Roles = "${var.role}"
  }
}

/*
* Configure internal DNS for the RDS
*/
resource "aws_route53_record" "private-dns" {
  zone_id = "${var.private_zone_id}"
  name = "${var.dns_name}"
  type = "A"
  ttl = "300"
  records = ["${aws_db_instance.mysql.endpoint}"]
  
  alias {
    zone_id = "${aws_db_instance.mysql.hosted_zone_id}"
    name = "${aws_db_instance.mysql.endpoint}"
    evaluate_target_health = true
  }
}
