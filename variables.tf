variable "vpc_cidr" {
    default = "10.0.0.0/16"
}
variable "public_subnet_cidr1" {
    default = "10.0.0.0/24"
}

variable "public_subnet_cidr2" {
    default = "10.0.1.0/24"
}

variable "ami_id" {
    default = "ami-06c68f701d8090592"
}

variable "instance_type" {
    default = "t2.micro"
}