variable "env" {}
variable "pillar_bucket" {}

resource "aws_iam_role" "wordpress_instance" {
  name = "${var.env}-wordpress-instance"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "wordpress_instance" {
  name = "${var.env}-wordpress-instance"
  path = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeTags"
      ],
      "Resource": [
        "*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.pillar_bucket}",
        "arn:aws:s3:::${var.pillar_bucket}/top.sls",
        "arn:aws:s3:::${var.pillar_bucket}/base",
        "arn:aws:s3:::${var.pillar_bucket}/base/*",
        "arn:aws:s3:::${var.pillar_bucket}/wordpress/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "wordpress_instance" {
  name = "${var.env}-wordpress-instance"
  roles = ["${aws_iam_role.wordpress_instance.name}"]
  policy_arn = "${aws_iam_policy.wordpress_instance.arn}"
}

resource "aws_iam_instance_profile" "wordpress_instance" {
  name = "${var.env}-wordpress-instance"
  roles = ["${aws_iam_role.wordpress_instance.name}"]
}

output "iam_role_wordpress_instance" {
  value = "${aws_iam_role.wordpress_instance.arn}"
  depends_on = ["aws_iam_policy_attachment.wordpress_instance"]
}

output "iam_profile_wordpress_instance" {
  value = "${aws_iam_instance_profile.wordpress_instance.name}"
  depends_on = ["aws_iam_policy_attachment.wordpress_instance"]
}
