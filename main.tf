provider "aws" {
  region = "${var.aws_region}"
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

#---- Load Balancer ----
resource "aws_elb" "pes_elb" {
  name = "pes-elb"

  subnets = ["${aws_subnet.pes_public1_subnet.id}",
    "${aws_subnet.pes_public2_subnet.id}",
  ]

  security_groups = ["${aws_security_group.pes_public_sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    timeout             = "${var.elb_timeout}"
    target              = "TCP:80"
    interval            = "${var.elb_interval}"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "pes-elb"
  }
}
