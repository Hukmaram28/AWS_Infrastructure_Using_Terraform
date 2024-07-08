resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "publicsubnet1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_subnet_cidr1
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "publicsubnet2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.public_subnet_cidr2
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "name" {
  vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "mypublicroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.name.id
  }
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.publicsubnet1.id
  route_table_id = aws_route_table.mypublicroute.id
}

resource "aws_route_table_association" "public2" {
  subnet_id      = aws_subnet.publicsubnet2.id
  route_table_id = aws_route_table.mypublicroute.id
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  vpc_id      = aws_vpc.myvpc.id
  description = "Security group for SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "hukma-11211j" {
  bucket = "hukma-ssjajas"
}

resource "aws_instance" "webserver1" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.publicsubnet1.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  user_data                   = base64encode(file("user_data.sh"))
  tags = {
    Name = "webserver1"
  }
}

resource "aws_instance" "webserver2" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.publicsubnet2.id
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  user_data                   = base64encode(file("user_data.sh"))
  tags = {
    Name = "webserver2"
  }
}

resource "aws_alb_target_group" "mytarget" {
    name     = "mytarget"
    port     = 80
    protocol = "HTTP"
    vpc_id   = aws_vpc.myvpc.id
    tags = {
    Name = "mytarget"
    }
    target_type = "instance"
    deregistration_delay = 30
    health_check {
        path                = "/"
        port                = "traffic-port"
    }
    depends_on = [aws_instance.webserver1, aws_instance.webserver2]
}

resource "aws_alb_target_group_attachment" "attalbtg" {
    target_group_arn = aws_alb_target_group.mytarget.arn
    target_id        = aws_instance.webserver1.id
    port             = 80
    depends_on       = [aws_instance.webserver1]
}

resource "aws_alb_target_group_attachment" "attalbtg2" {
    target_group_arn = aws_alb_target_group.mytarget.arn
    target_id        = aws_instance.webserver2.id 
    port             = 80
    depends_on       = [aws_instance.webserver2]
}

resource "aws_alb" "myALB" {
    name = "myALB"
    subnets = [aws_subnet.publicsubnet1.id, aws_subnet.publicsubnet2.id]
    security_groups = [aws_security_group.allow_ssh.id]
    tags = {
    Name = "myALB"
    }
    internal = false
}

resource "aws_alb_listener" "myListener" {
    load_balancer_arn = aws_alb.myALB.arn
    port              = 80
    protocol          = "HTTP"
    default_action {
        type             = "forward"
        target_group_arn = aws_alb_target_group.mytarget.arn
    }
}

output "alb" {
    value = aws_alb.myALB.dns_name
}