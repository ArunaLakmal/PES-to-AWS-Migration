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
