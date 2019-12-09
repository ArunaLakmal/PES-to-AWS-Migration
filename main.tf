provider "aws" {
  region = "${var.aws_region}"
}

#-----Deploying Networking Resources-----
module "networking" {
  source = "./networking"
  vpc_cidr           = "${var.vpc_cidr}"
  cidrs = "${var.cidrs}"
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
