provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

#---- VPC ----
resource "aws_vpc" "pes_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "pes_vpc"
  }
}

#---- IGW -----
resource "aws_internet_gateway" "pes_igw" {
  vpc_id = "${aws_vpc.pes_vpc.id}"

  tags = {
    Name = "pes_igw"
  }
}

resource "aws_eip" "pes_eip" {
  vpc        = true
  depends_on = ["aws_internet_gateway.pes_igw"]
}

resource "aws_nat_gateway" "pes_nat_gw" {
  allocation_id = "${aws_eip.pes_eip.id}"
  subnet_id     = "${aws_subnet.pes_public2_subnet.id}"
  depends_on    = ["aws_internet_gateway.pes_igw"]

  tags = {
    Name = "pes_nat_gw"
  }
}

#---- Public RT ----
resource "aws_route_table" "pes_public_rt" {
  vpc_id = "${aws_vpc.pes_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.pes_igw.id}"
  }

  tags = {
    Name = "pes_public"
  }
}

#---- private RT

resource "aws_route_table" "pes_private_rt" {
  vpc_id = "${aws_vpc.pes_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.pes_nat_gw.id}"
  }

  tags = {
    Name = "pes_private_rt"
  }
}

#---- Subnets ----

resource "aws_subnet" "pes_public1_subnet" {
  vpc_id                  = "${aws_vpc.pes_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "pes_public1"
  }
}

resource "aws_subnet" "pes_public2_subnet" {
  vpc_id                  = "${aws_vpc.pes_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "pes_public2"
  }
}

resource "aws_subnet" "pes_private1_subnet" {
  vpc_id                  = "${aws_vpc.pes_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "pes_private1"
  }
}

resource "aws_subnet" "pes_private2_subnet" {
  vpc_id                  = "${aws_vpc.pes_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "pes_private2"
  }
}

resource "aws_subnet" "pes_rds1_subnet" {
  vpc_id                  = "${aws_vpc.pes_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = {
    Name = "pes_rds1"
  }
}

resource "aws_subnet" "pes_rds2_subnet" {
  vpc_id                  = "${aws_vpc.pes_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = {
    Name = "pes_rds2"
  }
}

#----- RDS Subnet group for multiple subnets -----

resource "aws_db_subnet_group" "pes_db_subnet_group" {
  name = "pes_rds_subnet_group"

  subnet_ids = ["${aws_subnet.pes_rds1_subnet.id}",
    "${aws_subnet.pes_rds2_subnet.id}",
  ]

  tags = {
    Name = "pes_rds_subnet_group"
  }
}

#---- Subnet Associations ----
resource "aws_route_table_association" "pes_public1_association" {
  subnet_id      = "${aws_subnet.pes_public1_subnet.id}"
  route_table_id = "${aws_route_table.pes_public_rt.id}"
}

resource "aws_route_table_association" "pes_public2_association" {
  subnet_id      = "${aws_subnet.pes_public2_subnet.id}"
  route_table_id = "${aws_route_table.pes_public_rt.id}"
}

resource "aws_route_table_association" "pes_private1_association" {
  subnet_id      = "${aws_subnet.pes_private1_subnet.id}"
  route_table_id = "${aws_route_table.pes_private_rt.id}"
}

resource "aws_route_table_association" "pes_private2_association" {
  subnet_id      = "${aws_subnet.pes_private2_subnet.id}"
  route_table_id = "${aws_route_table.pes_private_rt.id}"
}

#---- Security Groups -----

#Public Security Group
resource "aws_security_group" "pes_public_sg" {
  name        = "pes_public_sg"
  description = "ELB Public Access"
  vpc_id      = "${aws_vpc.pes_vpc.id}"

  #Allow SSH

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Http Allow
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Out going all allow
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Private Security Group

resource "aws_security_group" "pes_private_sg" {
  name        = "pes_private_sg"
  description = "Access for Private Instances"
  vpc_id      = "${aws_vpc.pes_vpc.id}"

  #VPC Local Traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#RDS Security Group

resource "aws_security_group" "rds_security_group" {
  name        = "rds_security_group"
  description = "Access for RDS Instances"
  vpc_id      = "${aws_vpc.pes_vpc.id}"

  #SQL Access from Public and Private Security Groups
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"

    security_groups = ["${aws_security_group.pes_public_sg.id}",
      "${aws_security_group.pes_private_sg.id}",
    ]
  }
}

#----- Key Pair ------
resource "aws_key_pair" "pes_key" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#----- RDS Instance -----
resource "aws_db_instance" "pes_rds_instance" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7.22"
  instance_class         = "${var.db_instance_class}"
  name                   = "${var.dbname}"
  username               = "${var.dbuser}"
  password               = "${var.dbpassword}"
  db_subnet_group_name   = "${aws_db_subnet_group.pes_db_subnet_group.name}"
  vpc_security_group_ids = ["${aws_security_group.rds_security_group.id}"]
  skip_final_snapshot    = true
}

#----- AMI -----
data "aws_ami" "golden_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "user-init" {
  template = "${file("${path.module}/userdata.tpl")}"
}

#----- Launch Configuration ----
resource "aws_launch_configuration" "pes_lc" {
  name_prefix     = "pes_lc-"
  image_id        = "${data.aws_ami.golden_ami.id}"
  instance_type   = "${var.pes_instance_type}"
  key_name        = "${aws_key_pair.pes_key.id}"
  user_data       = "${data.template_file.user-init.rendered}"
  security_groups = ["${aws_security_group.pes_private_sg.id}", ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb" "pes-app-alb" {
  name               = "pes-app-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = ["${aws_security_group.pes_public_sg.id}"]

  subnets = ["${aws_subnet.pes_public1_subnet.id}",
    "${aws_subnet.pes_public2_subnet.id}",
  ]

  enable_deletion_protection = true
}

resource "aws_alb_target_group" "pes_target_group_one" {
  name     = "pes-target-group-one"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.pes_vpc.id}"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/"
    port                = 2001
    healthy_threshold   = 6
    unhealthy_threshold = 2
    timeout             = 2
    interval            = 5
    matcher             = "200"
  }
}

resource "aws_alb_listener" "pes_alb_listener" {
  default_action {
    target_group_arn = "${aws_alb_target_group.pes_target_group_one.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.pes-app-alb.arn}"
  port              = 80
  protocol          = "HTTP"
}

resource "aws_alb_listener_rule" "pes_rule_1" {
  action {
    target_group_arn = "${aws_alb_target_group.pes_target_group_one.arn}"
    type             = "forward"
  }

  condition {
    field = "host-header"

    values = ["employee-services-stg.test.com"]
  }

  listener_arn = "${aws_alb_listener.pes_alb_listener.id}"
  priority     = 100
}

resource "aws_autoscaling_group" "pes_asg" {
  name                      = "pes-app-asg"
  max_size                  = 6
  min_size                  = 2
  health_check_grace_period = 300
  health_check_type         = "EC2"
  desired_capacity          = 2
  force_delete              = true
  launch_configuration      = "${aws_launch_configuration.pes_lc.id}"

  vpc_zone_identifier = ["${aws_subnet.pes_private1_subnet.id}",
    "${aws_subnet.pes_private2_subnet.id}",
  ]

  target_group_arns = ["${aws_alb_target_group.pes_target_group_one.arn}"]

  lifecycle {
    create_before_destroy = true
  }
}
