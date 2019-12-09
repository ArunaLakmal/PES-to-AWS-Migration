variable "aws_region" {}
variable "aws_profile" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = "map"
}

variable "db_instance_class" {}
variable "dbname" {}
variable "dbuser" {}
variable "dbpassword" {}
