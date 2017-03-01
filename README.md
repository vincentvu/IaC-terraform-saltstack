# Infrastructure as Code with Terraform and Saltstack

## General idea

**Note**: Use this tutorial on your AWS free tier account. 

In this tutorial, you will set up  wordpress system on AWS by using Terraform v0.8.7 and Saltstack v2016.3.3. 

Terraform will be used to create AWS resources:
* module "demo-vpc": defines a VPC on AWS.
* module "demo-iam-profiles": defines IAM role which can be applied on wordpress EC2 instance. Saltstack on this instance needs to read pillar from S3 bucket to configure the server itself. The best way is to create and IAM role and assigned this role to the EC2 instace.
* module "demo-SGs": defines some Security Groups to allow in/out network traffic between subnet and outside world.
* module "demo-key-pair": creates a key-pair for EC2 instance.
* module "demo-private-dns-zone": Create a DNS zone for internal network of demo-vpc.
* module "demo-wordpress-instance": creates an EC2 instance. Saltstack will install/configure NTP client, docker and create docker container of Wordpress.
* module "demo-wordpress-db": create mysql database instance for wordpress application.

## Setup 

Here are some steps to set up your personal computer 
### Create AWS free tier account

Check information at [here](https://aws.amazon.com/free/) to create your own free AWS account.

### Install terraform

Download terraform from [here](https://www.terraform.io/downloads.html) and copy terraform executable file to folder ```/usr/bin```

Verify terraform Version
```
$ terraform -version
Terraform v0.8.7
```

### instlall aws cli 

Following this [guide](http://docs.aws.amazon.com/cli/latest/userguide/installing.html) to install AWS cli.

###


### Configure AWS credential
Create AWS credential on AWS console by Following this [guide](http://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html). Then use command ```aws configure``` to setup credential for your account.

### Create SSH key-pair
```
$ ssh-keygen -f demo
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in demo.
Your public key has been saved in demo.pub.
The key fingerprint is:
fc:8a:4b:e6:ba:ab:d4:e8:1e:27:1c:2d:e4:6e:fb:60 admin@ip-10-10-101-214
The key's randomart image is:
+---[RSA 2048]----+
|                 |
|                 |
|  .              |
| o .   .         |
|  + .   S        |
| o =     .       |
|  E o o   .      |
| = * + . .       |
| .=o=++..        |
+-----------------+
admin@ip-10-10-101-214:~$ ls -l
total 8
-rw------- 1 admin admin 1675 Mar  1 19:38 demo
-rw-r--r-- 1 admin admin  404 Mar  1 19:38 demo.pub
```
Put the content of ```demo``` file on variable ```public_key``` of module ```demo-key-pair``` on ```terraform-demo/demo.tf``` file

### Change to correct Region on AWS console

## Saltstack
### Formulas

Formulas is on Github repo: https://github.com/vincentvu/demo-saltstack-formulas

In this repo, we use only ```wordpress-formula``` for only.

### Pillars

Pillars information is located at ```saltstack-pillars-demo``` folder.

The pillars need to be available on S3 bucket first
1. Create a s3 bucket
```
$ aws s3 mb s3://vincentvu-pillars-demo
make_bucket: vincentvu-pillars-demo
```
2. Synchronize the all pillars to this bucket
```
$ aws s3 sync saltstack-pillars-demo/ s3://vincentvu-pillars-demo
upload: saltstack-pillars-demo/top.sls to s3://vincentvu-pillars-demo/top.sls
upload: saltstack-pillars-demo/base/ntp.sls to s3://vincentvu-pillars-demo/base/ntp.sls
upload: saltstack-pillars-demo/wordpress/init.sls to s3://vincentvu-pillars-demo/wordpress/init.sls
```
3. Update iam role demo and user-data

Update ```pillar_bucket``` variable in the file ```terraform-demo/demo.tf``` 
```
module "demo-iam-profiles" {
  source = "../terraform-modules/IAM/iam-profiles"
  env = "demo"
  pillar_bucket = "vincentvu-pillars-demo"
}
```

Update variable ```PILLAR_BUCKET``` in ```terraform-demo/ec2-user-data/demo-user-data.yaml```
```
      PILLAR_BUCKET="vincentvu-pillars-demo"
```

## Terraform
### Create a terraform plan

* Get/update terraform modules
```
$ cd terraform-demo
$ terraform get -update
Get: git::https://github.com/terraform-community-modules/tf_aws_vpc.git
Get: file:///....
```

* Generate terraform plan into file ```tf.out```. We can review which resources it will create on AWS

```
$ terraform plan -out=tf.out
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.


The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Your plan was also saved to the path below. Call the "apply" subcommand
with this plan file and Terraform will exactly execute this execution
plan.

Path: tf.out

+ module.demo-key-pair.aws_key_pair.key_pair
    fingerprint: "<computed>"
    key_name:    "demo"
    public_key:  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDfSf76KmWIT3TNcxp107zG0LPi1qchhl+bjTYpApu2f2WDeN/dcjpDTSTfWuPUsih8KdQLT9Uw2qkgkherRIF1JU156YuOqAdA5G2uyBT69dF7htl8DSIgiltLxLPv7lI6EnX/aX6LcTDwF8v/wlrOJvWuUkfoAvyyX/fArgR1rE2UbTkQ8Dgn0kdZjHGc0v+GRkr8vP+VyHmXa2mfhJgnthv76xTewhxjYxW4jRZA7Fu5CTBUjjTOBWq2pY22BBwm4ZGw3X3NdSTSFruKLdtemH/8nUZwG0FXbzQf7tUQQ2EvutXCDAnBck3eIerRHyQSY88MapLjB03fd11bgROukXau/3jo8MNt3sdvfeDc3FlTdmth7sEn6czxiwNEGuWf/+c8dY9xK15Fm+WEYpf5ILufcV6aIwY/XZi+7B+xtgsgTrljDYq5TN3aEfKsLm8Qqo3oo680mD5hmlEUilDIqTbpHQnSj9FcmRhXdSve8puMbZHi6cARyQlYPT0Py/81yLSUo/0RwOBrdUwstyRayUG40zIKMqcOmyWOV4AQQbzCScy+v9LcbR1+RmykGd0pg2JR8nOSflaOS1GWTbrhOE+MrU4NkCJ2+A9zQGvYen1rflQ2Lym0iQRLNVn1U/quYq9gC23/Og3DtAzCzeYp6PMyRMPO8VPBxsOC2JsACw== vincent.vu@rubikloud.com"

+ module.demo-iam-profiles.aws_iam_instance_profile.wordpress_instance
    arn:              "<computed>"
    create_date:      "<computed>"
    name:             "demo-wordpress-instance"
    path:             "/"
    roles.#:          "1"
    roles.1455848035: "demo-wordpress-instance"
    unique_id:        "<computed>"

+ module.demo-iam-profiles.aws_iam_policy.wordpress_instance
    arn:    "<computed>"
    name:   "demo-wordpress-instance"
    path:   "/"
    policy: "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"ec2:DescribeTags\"\n      ],\n      \"Resource\": [\n        \"*\"\n      ]\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"s3:GetObject\",\n        \"s3:ListBucket\"\n      ],\n      \"Resource\": [\n        \"arn:aws:s3:::vincentvu-pillars-demo\",\n        \"arn:aws:s3:::vincentvu-pillars-demo/top.sls\",\n        \"arn:aws:s3:::vincentvu-pillars-demo/base\",\n        \"arn:aws:s3:::vincentvu-pillars-demo/base/*\",\n        \"arn:aws:s3:::vincentvu-pillars-demo/wordpress/*\"\n      ]\n    },\n    {\n      \"Effect\": \"Allow\",\n      \"Action\": [\n        \"logs:CreateLogGroup\",\n        \"logs:CreateLogStream\",\n        \"logs:PutLogEvents\",\n        \"logs:DescribeLogStreams\"\n      ],\n      \"Resource\": [\n        \"arn:aws:logs:*:*:*\"\n      ]\n    }\n  ]\n}\n"

+ module.demo-iam-profiles.aws_iam_policy_attachment.wordpress_instance
    name:             "demo-wordpress-instance"
    policy_arn:       "${aws_iam_policy.wordpress_instance.arn}"
    roles.#:          "1"
    roles.1455848035: "demo-wordpress-instance"

+ module.demo-iam-profiles.aws_iam_role.wordpress_instance
    arn:                "<computed>"
    assume_role_policy: "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Action\": \"sts:AssumeRole\",\n      \"Principal\": {\n        \"Service\": \"ec2.amazonaws.com\"\n      },\n      \"Effect\": \"Allow\",\n      \"Sid\": \"\"\n    }\n  ]\n}\n"
    create_date:        "<computed>"
    name:               "demo-wordpress-instance"
    path:               "/"
    unique_id:          "<computed>"

+ module.demo-vpc.aws_internet_gateway.mod
    tags.%:           "2"
    tags.Environment: "demo"
    tags.Name:        "demo-igw"
    vpc_id:           "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_route.public_internet_gateway
    destination_cidr_block:     "0.0.0.0/0"
    destination_prefix_list_id: "<computed>"
    gateway_id:                 "${aws_internet_gateway.mod.id}"
    instance_id:                "<computed>"
    instance_owner_id:          "<computed>"
    nat_gateway_id:             "<computed>"
    network_interface_id:       "<computed>"
    origin:                     "<computed>"
    route_table_id:             "${aws_route_table.public.id}"
    state:                      "<computed>"

+ module.demo-vpc.aws_route_table.private.0
    route.#:          "<computed>"
    tags.%:           "2"
    tags.Environment: "demo"
    tags.Name:        "demo-rt-private-us-east-1a"
    vpc_id:           "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_route_table.private.1
    route.#:          "<computed>"
    tags.%:           "2"
    tags.Environment: "demo"
    tags.Name:        "demo-rt-private-us-east-1b"
    vpc_id:           "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_route_table.private.2
    route.#:          "<computed>"
    tags.%:           "2"
    tags.Environment: "demo"
    tags.Name:        "demo-rt-private-us-east-1c"
    vpc_id:           "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_route_table.public
    route.#:          "<computed>"
    tags.%:           "2"
    tags.Environment: "demo"
    tags.Name:        "demo-rt-public"
    vpc_id:           "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_route_table_association.private.0
    route_table_id: "${element(aws_route_table.private.*.id, count.index)}"
    subnet_id:      "${element(aws_subnet.private.*.id, count.index)}"

+ module.demo-vpc.aws_route_table_association.private.1
    route_table_id: "${element(aws_route_table.private.*.id, count.index)}"
    subnet_id:      "${element(aws_subnet.private.*.id, count.index)}"

+ module.demo-vpc.aws_route_table_association.private.2
    route_table_id: "${element(aws_route_table.private.*.id, count.index)}"
    subnet_id:      "${element(aws_subnet.private.*.id, count.index)}"

+ module.demo-vpc.aws_route_table_association.public.0
    route_table_id: "${aws_route_table.public.id}"
    subnet_id:      "${element(aws_subnet.public.*.id, count.index)}"

+ module.demo-vpc.aws_route_table_association.public.1
    route_table_id: "${aws_route_table.public.id}"
    subnet_id:      "${element(aws_subnet.public.*.id, count.index)}"

+ module.demo-vpc.aws_route_table_association.public.2
    route_table_id: "${aws_route_table.public.id}"
    subnet_id:      "${element(aws_subnet.public.*.id, count.index)}"

+ module.demo-vpc.aws_subnet.private.0
    availability_zone:       "us-east-1a"
    cidr_block:              "10.10.1.0/24"
    map_public_ip_on_launch: "false"
    tags.%:                  "2"
    tags.Environment:        "demo"
    tags.Name:               "demo-subnet-private-us-east-1a"
    vpc_id:                  "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_subnet.private.1
    availability_zone:       "us-east-1b"
    cidr_block:              "10.10.2.0/24"
    map_public_ip_on_launch: "false"
    tags.%:                  "2"
    tags.Environment:        "demo"
    tags.Name:               "demo-subnet-private-us-east-1b"
    vpc_id:                  "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_subnet.private.2
    availability_zone:       "us-east-1c"
    cidr_block:              "10.10.3.0/24"
    map_public_ip_on_launch: "false"
    tags.%:                  "2"
    tags.Environment:        "demo"
    tags.Name:               "demo-subnet-private-us-east-1c"
    vpc_id:                  "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_subnet.public.0
    availability_zone:       "us-east-1a"
    cidr_block:              "10.10.101.0/24"
    map_public_ip_on_launch: "true"
    tags.%:                  "2"
    tags.Environment:        "demo"
    tags.Name:               "demo-subnet-public-us-east-1a"
    vpc_id:                  "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_subnet.public.1
    availability_zone:       "us-east-1b"
    cidr_block:              "10.10.102.0/24"
    map_public_ip_on_launch: "true"
    tags.%:                  "2"
    tags.Environment:        "demo"
    tags.Name:               "demo-subnet-public-us-east-1b"
    vpc_id:                  "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_subnet.public.2
    availability_zone:       "us-east-1c"
    cidr_block:              "10.10.103.0/24"
    map_public_ip_on_launch: "true"
    tags.%:                  "2"
    tags.Environment:        "demo"
    tags.Name:               "demo-subnet-public-us-east-1c"
    vpc_id:                  "${aws_vpc.mod.id}"

+ module.demo-vpc.aws_vpc.mod
    cidr_block:                "10.10.0.0/16"
    default_network_acl_id:    "<computed>"
    default_route_table_id:    "<computed>"
    default_security_group_id: "<computed>"
    dhcp_options_id:           "<computed>"
    enable_classiclink:        "<computed>"
    enable_dns_hostnames:      "true"
    enable_dns_support:        "true"
    instance_tenancy:          "<computed>"
    main_route_table_id:       "<computed>"
    tags.%:                    "2"
    tags.Environment:          "demo"
    tags.Name:                 "demo"

+ module.demo-private-dns-zone.aws_route53_zone.private_zone
    comment:          "Managed by Terraform"
    force_destroy:    "false"
    name:             "demo.local"
    name_servers.#:   "<computed>"
    tags.%:           "1"
    tags.Environment: "demo"
    vpc_id:           "${var.vpc_id}"
    vpc_region:       "<computed>"
    zone_id:          "<computed>"

+ module.demo-SGs.aws_security_group.public_wordpress
    description:                          "A security group for public wordpresss in demo environment"
    egress.#:                             "1"
    egress.482069346.cidr_blocks.#:       "1"
    egress.482069346.cidr_blocks.0:       "0.0.0.0/0"
    egress.482069346.from_port:           "0"
    egress.482069346.prefix_list_ids.#:   "0"
    egress.482069346.protocol:            "-1"
    egress.482069346.security_groups.#:   "0"
    egress.482069346.self:                "false"
    egress.482069346.to_port:             "0"
    ingress.#:                            "3"
    ingress.2214680975.cidr_blocks.#:     "1"
    ingress.2214680975.cidr_blocks.0:     "0.0.0.0/0"
    ingress.2214680975.from_port:         "80"
    ingress.2214680975.protocol:          "tcp"
    ingress.2214680975.security_groups.#: "0"
    ingress.2214680975.self:              "false"
    ingress.2214680975.to_port:           "80"
    ingress.2541437006.cidr_blocks.#:     "1"
    ingress.2541437006.cidr_blocks.0:     "0.0.0.0/0"
    ingress.2541437006.from_port:         "22"
    ingress.2541437006.protocol:          "tcp"
    ingress.2541437006.security_groups.#: "0"
    ingress.2541437006.self:              "false"
    ingress.2541437006.to_port:           "22"
    ingress.2617001939.cidr_blocks.#:     "1"
    ingress.2617001939.cidr_blocks.0:     "0.0.0.0/0"
    ingress.2617001939.from_port:         "443"
    ingress.2617001939.protocol:          "tcp"
    ingress.2617001939.security_groups.#: "0"
    ingress.2617001939.self:              "false"
    ingress.2617001939.to_port:           "443"
    name:                                 "demo-public_wordpress"
    owner_id:                             "<computed>"
    tags.%:                               "2"
    tags.Environment:                     "demo"
    tags.Name:                            "demo-public-wordpress"
    vpc_id:                               "${var.vpc_id}"

+ module.demo-SGs.aws_security_group.public_wordpress_db
    description:                          "A security group for for database of wordpresss in demo environment"
    egress.#:                             "1"
    egress.482069346.cidr_blocks.#:       "1"
    egress.482069346.cidr_blocks.0:       "0.0.0.0/0"
    egress.482069346.from_port:           "0"
    egress.482069346.prefix_list_ids.#:   "0"
    egress.482069346.protocol:            "-1"
    egress.482069346.security_groups.#:   "0"
    egress.482069346.self:                "false"
    egress.482069346.to_port:             "0"
    ingress.#:                            "1"
    ingress.~471043921.cidr_blocks.#:     "0"
    ingress.~471043921.from_port:         "3306"
    ingress.~471043921.protocol:          "tcp"
    ingress.~471043921.security_groups.#: "<computed>"
    ingress.~471043921.self:              "false"
    ingress.~471043921.to_port:           "3306"
    name:                                 "demo-public-wordpress-db"
    owner_id:                             "<computed>"
    tags.%:                               "2"
    tags.Environment:                     "demo"
    tags.Name:                            "demo-public-wordpress"
    vpc_id:                               "${var.vpc_id}"

+ module.demo-wordpress-db.aws_db_instance.mysql
    address:                    "<computed>"
    allocated_storage:          "30"
    apply_immediately:          "<computed>"
    arn:                        "<computed>"
    auto_minor_version_upgrade: "true"
    availability_zone:          "<computed>"
    backup_retention_period:    "1"
    backup_window:              "14:17-14:47"
    character_set_name:         "<computed>"
    copy_tags_to_snapshot:      "false"
    db_subnet_group_name:       "${aws_db_subnet_group.mysql.id}"
    endpoint:                   "<computed>"
    engine:                     "mysql"
    engine_version:             "5.5.46"
    hosted_zone_id:             "<computed>"
    identifier:                 "demo-wordpress"
    instance_class:             "db.t2.micro"
    kms_key_id:                 "<computed>"
    license_model:              "<computed>"
    maintenance_window:         "sat:03:27-sat:03:57"
    monitoring_interval:        "0"
    monitoring_role_arn:        "<computed>"
    multi_az:                   "false"
    name:                       "wordpress"
    option_group_name:          "<computed>"
    parameter_group_name:       "<computed>"
    password:                   "<sensitive>"
    port:                       "3306"
    publicly_accessible:        "false"
    replicas.#:                 "<computed>"
    skip_final_snapshot:        "true"
    status:                     "<computed>"
    storage_type:               "gp2"
    tags.%:                     "2"
    tags.Environment:           "demo"
    tags.Roles:                 "wordpress-demo"
    timezone:                   "<computed>"
    username:                   "admin"
    vpc_security_group_ids.#:   "<computed>"

+ module.demo-wordpress-db.aws_db_subnet_group.mysql
    arn:          "<computed>"
    description:  "Managed by Terraform"
    name:         "demo-mysql-wordpress"
    subnet_ids.#: "<computed>"

+ module.demo-wordpress-db.aws_route53_record.private-dns
    fqdn:      "<computed>"
    name:      "wordpress-db.demo.local"
    records.#: "<computed>"
    ttl:       "300"
    type:      "CNAME"
    zone_id:   "${var.private_zone_id}"

+ module.demo-wordpress-instance.aws_instance.instance
    ami:                                       "ami-b14ba7a7"
    associate_public_ip_address:               "true"
    availability_zone:                         "<computed>"
    disable_api_termination:                   "false"
    ebs_block_device.#:                        "<computed>"
    ebs_optimized:                             "false"
    ephemeral_block_device.#:                  "<computed>"
    iam_instance_profile:                      "demo-wordpress-instance"
    instance_state:                            "<computed>"
    instance_type:                             "t2.micro"
    key_name:                                  "demo"
    network_interface_id:                      "<computed>"
    placement_group:                           "<computed>"
    private_dns:                               "<computed>"
    private_ip:                                "<computed>"
    public_dns:                                "<computed>"
    public_ip:                                 "<computed>"
    root_block_device.#:                       "1"
    root_block_device.0.delete_on_termination: "true"
    root_block_device.0.iops:                  "<computed>"
    root_block_device.0.volume_size:           "20"
    root_block_device.0.volume_type:           "<computed>"
    security_groups.#:                         "<computed>"
    source_dest_check:                         "true"
    subnet_id:                                 "${element(var.subnet_ids, var.subnet_index)}"
    tags.%:                                    "3"
    tags.Environment:                          "demo"
    tags.Name:                                 "demo-wordpress"
    tags.Roles:                                "wordpress"
    tenancy:                                   "<computed>"
    user_data:                                 "f68767bfa00d0f5a00c7e408684e201ff90c4f2d"
    vpc_security_group_ids.#:                  "<computed>"


Plan: 31 to add, 0 to change, 0 to destroy.
```
As you can see, terraform will create 31 resource on AWS.

### Apply the plan to create AWS resources

* Execute the generated plan
```
$ terraform apply tf.out
module.demo-iam-profiles.aws_iam_role.wordpress_instance: Creating...
...
Apply complete! Resources: 31 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```
After about 10 munites, all resources will be created.

* Get information of the EC2 instance
```
$ terraform output -module=demo-wordpress-instance
id = i-078358eae8618ff58
private_dns = 10.10.101.203
private_ip = 10.10.101.203
public_dns = ec2-54-234-142-9.compute-1.amazonaws.com
public_ip = 54.234.142.9
```
We can see the public IP of the EC2 instance is ```54.234.142.9```

Use your private key to connect this EC2 instance

```
$ ssh -i [path-to-your-private-key] admin@54.234.142.9
The authenticity of host '54.234.142.9 (54.234.142.9)' can't be established.
ECDSA key fingerprint is SHA256:exnvtIUrPyPJhjnKKoBfJf6yO6vMuR7+oAZNu/i0aH0.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '54.234.142.9' (ECDSA) to the list of known hosts.

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
admin@ip-10-10-101-203:~$ 
```

Saltstack will configure Wordpress docker automatically with confiruation in pillar on S3 bucket.

```
admin@ip-10-10-101-203:~$ sudo su -
root@ip-10-10-101-203:~# docker ps
CONTAINER ID        IMAGE               COMMAND                CREATED             STATUS              PORTS                NAMES
f94960538910        wordpress:latest    "docker-entrypoint.s   2 minutes ago       Up 2 minutes        0.0.0.0:80->80/tcp   wordpress           

~# systemctl status docker-wordpress -l
● docker-wordpress.service - Docker container for wordpress
   Loaded: loaded (/etc/systemd/system/docker-wordpress.service; enabled)
   Active: active (running) since Wed 2017-03-01 05:56:09 UTC; 8min ago
  Process: 18935 ExecStopPost=/usr/bin/docker rm -f wordpress (code=exited, status=1/FAILURE)
  Process: 18927 ExecStop=/usr/bin/docker stop wordpress (code=exited, status=1/FAILURE)
 Main PID: 18945 (docker)
   CGroup: /system.slice/docker-wordpress.service
           └─18945 /usr/bin/docker run -e WORDPRESS_DB_HOST=wordpress-db.demo.local -e WORDPRESS_DB_USER=admin -e WORDPRESS_DB_PASSWORD=Xg4gc30b -p 80:80 --rm --name=wordpress wordpress
```

* Use your browser to access the wordpress at http://http://54.234.142.9

### Destroy resources

After exploring Wordpress ssytem, we can destroy the AWS resource to save money.

We have 2 options to destroy resources:

1. Destroy resources one by one. For example, we can destroy ```demo-wordpress-db``` module by following the steps below

* Create a plan to destroy

```
$ terraform plan -destroy -target=module.demo-wordpress-db -out=tf.out
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.

module.demo-wordpress-db.aws_db_subnet_group.mysql: Refreshing state... (ID: demo-mysql-wordpress)
module.demo-wordpress-db.aws_db_instance.mysql: Refreshing state... (ID: demo-wordpress)
module.demo-wordpress-db.aws_route53_record.private-dns: Refreshing state... (ID: Z2K4HG3LSCK7N2_wordpress-db.demo.local_CNAME)

The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Your plan was also saved to the path below. Call the "apply" subcommand
with this plan file and Terraform will exactly execute this execution
plan.

Path: tf.out

- module.demo-wordpress-db.aws_db_instance.mysql

- module.demo-wordpress-db.aws_db_subnet_group.mysql

- module.demo-wordpress-db.aws_route53_record.private-dns


Plan: 0 to add, 0 to change, 3 to destroy.
```

As you can see, terraform will destory 3 components of this module.

* If you are not sure what includes in the module, you can verify each component with ```terraform state show```

```
$ terraform state show module.demo-wordpress-db.aws_db_instance.mysql
id                                = demo-wordpress
address                           = demo-wordpress.cwf1xeyubqhp.us-east-1.rds.amazonaws.com
allocated_storage                 = 30
arn                               = arn:aws:rds:us-east-1:219615105485:db:demo-wordpress
auto_minor_version_upgrade        = true
availability_zone                 = us-east-1b
backup_retention_period           = 1
backup_window                     = 14:17-14:47
copy_tags_to_snapshot             = false
db_subnet_group_name              = demo-mysql-wordpress
endpoint                          = demo-wordpress.cwf1xeyubqhp.us-east-1.rds.amazonaws.com:3306
engine                            = mysql
engine_version                    = 5.5.46
hosted_zone_id                    = Z2R2ITUGPM61AM
identifier                        = demo-wordpress
instance_class                    = db.t2.micro
iops                              = 0
kms_key_id                        = 
license_model                     = general-public-license
maintenance_window                = sat:03:27-sat:03:57
monitoring_interval               = 0
multi_az                          = false
name                              = wordpress
option_group_name                 = default:mysql-5-5
parameter_group_name              = default.mysql5.5
password                          = Xg4gc30b
port                              = 3306
publicly_accessible               = false
replicas.#                        = 0
replicate_source_db               = 
security_group_names.#            = 0
skip_final_snapshot               = true
status                            = available
storage_encrypted                 = false
storage_type                      = gp2
tags.%                            = 2
tags.Environment                  = demo
tags.Roles                        = wordpress-demo
timezone                          = 
username                          = admin
vpc_security_group_ids.#          = 1
vpc_security_group_ids.3626150020 = sg-ef392793
```

When everything is verified, you can continue to apply the generate plan to destroy resource.
```
terraform apply tf.out
```

2. Destroy all AWS resources which are defined in the terraform state at once.
```
terraform plan -destroy -out=tf.out
terraform apply tf.out
```


