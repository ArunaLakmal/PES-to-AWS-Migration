variable "env" {
  description = "env: dev or prod"
}
variable "aws_region" {}
variable "aws_profile" {}
data "aws_availability_zones" "available" {}
variable "vpc_cidr" {}

variable "cidrs" {
  type = "map"
}
variable "key_name" {}
variable "public_key_path" {}
variable "db_instance_class" {}
variable "dbname" {}
variable "dbuser" {}
variable "dbpassword" {}
variable "pes_asg_name" {
  type        = "map"
  description = "Name of the asg."
  default = {
    dev  = "pesdev"
    prod = "pesprod"
  }
}
variable "pesalbname" {
  type        = "map"
  description = "Name of the ALB"
  default = {
    dev  = "pesdevalb"
    prod = "pesprodalb"
  }
}
variable "pestgname" {
  type        = "map"
  description = "target group one"
  default = {
    dev  = "pes-dev-tg-one"
    prod = "pes-prod-tg-one"
  }
}
variable "pes_listener" {
  type        = "map"
  description = "listener test"
  default = {
    dev  = "pes-dev-listener"
    prod = "pes-prod-listener"
  }
}

variable "elb_healthy_threshold" {}
variable "elb_unhealthy_threshold" {}
variable "elb_timeout" {}
variable "elb_interval" {}
variable "pes_instance_type" {}
