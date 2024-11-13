# provider "aws" {
#   region = "us-west-1"

# }

# #vpc

# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"

#   tags = {
#     Name = "wordpress_vpc"
#   }
# }
# # PubliC Subnet 1AZ
# resource "aws_subnet" "public-subnet1AZ1" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "us-west-1a"

#   tags = {
#     Name = "public-subnet1AZ1"
#   }

# }

# resource "aws_subnet" "private-webserverAZ1" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.32.0/24"
#   map_public_ip_on_launch = false
#   availability_zone       = "us-west-1a"

#   tags = {
#     Name = "private-webserverAZ1"
#   }

# }

# resource "aws_subnet" "public-subnet2AZ2" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.2.0/24"
#   map_public_ip_on_launch = true
#   availability_zone       = "us-west-1c"

#   tags = {
#     Name = "public-subnet2AZ2"
#   }

# }

# resource "aws_subnet" "private-webserverAZ2" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.48.0/24"
#   map_public_ip_on_launch = false
#   availability_zone       = "us-west-1c"

#   tags = {
#     Name = "private-webserverAZ1"
#   }

# }
# resource "aws_internet_gateway" "igw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "igw"
#   }
# }
# resource "aws_route_table" "pulic-rt" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.igw.id
#   }

#   tags = {
#     Name = "Public-rt"
#   }

# }

# locals {
#   public_sub = {
#     "subnet1" = aws_subnet.public-subnet1AZ1.id,
#     "subnet2" = aws_subnet.public-subnet2AZ2.id
#   }


# }


# resource "aws_route_table_association" "public-assoc" {
#   subnet_id      = each.value
#   route_table_id = aws_route_table.pulic-rt.id
#   for_each       = local.public_sub

# }


# resource "aws_key_pair" "bash" {
#   key_name   = "bash-key"
#   public_key = file("bash.pem.pub")

# }

# resource "aws_instance" "public-subnet1a" {
#   ami                         = "ami-04fdea8e25817cd69"
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public-subnet1AZ1.id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.allow-alb1.id]
#   key_name                    = aws_key_pair.bash.key_name

#   user_data = <<-EOF
#                #!/bin/bash
#                yum update -y
#                yum install -y httpd
#                yum install -y php php-mysqlnd
#                amazon-linux-extras install -y php7.4
#                systemctl start httpd
#                systemctl enable httpd
#                EOF

#   tags = {
#     Name = "webserver1"
#   }
# }

# resource "aws_instance" "public-subnet2a" {
#   ami                         = "ami-04fdea8e25817cd69"
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.public-subnet2AZ2.id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.allow-alb1.id]
#   key_name                    = aws_key_pair.bash.key_name
  

#   user_data = <<-EOF
#                #!/bin/bash
#                yum update -y
#                yum install -y httpd
#                yum install -y php php-mysqlnd
#                amazon-linux-extras install -y php7.4
#                systemctl start httpd
#                systemctl enable httpd
#                EOF

#   tags = {
#     Name = "webserver2"
#   }
# }

# # Public SG
# resource "aws_security_group" "allow-alb1" {
#   name        = "allow alb"
#   description = "Allow Alb for this public instance"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress  {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   } 



# }
# resource "aws_security_group_rule" "allow-abl2" {
#   type              = "ingress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   security_group_id = aws_security_group.allow-alb1.id
#   source_security_group_id = aws_security_group.albsg.id
#   }

# #private

# resource "aws_instance" "private-subnet1a" {
#   ami                         = "ami-04fdea8e25817cd69"
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.private-webserverAZ1.id
#   associate_public_ip_address = false
#   vpc_security_group_ids      = [aws_security_group.private-sg.id]

#   tags = {
#     Name = "webserver2"
#   }
# }

# resource "aws_instance" "private-subnet2a" {
#   ami                         = "ami-04fdea8e25817cd69"
#   instance_type               = "t2.micro"
#   subnet_id                   = aws_subnet.private-webserverAZ2.id
#   associate_public_ip_address = false
#   vpc_security_group_ids      = [aws_security_group.private-sg.id]

#   tags = {
#     Name = "webserver2"
#   }
# }

# #sg
# resource "aws_security_group" "private-sg" {
#   name = "not-allowed"
#   description = "Private instance"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

# }

# #alb
# resource "aws_alb" "alb-wordpress" {
#   name = "alb-terrafrom"
#   internal = false
#   load_balancer_type = "application"
#   security_groups = [aws_security_group.albsg.id]
#   subnets = [aws_subnet.public-subnet1AZ1.id, aws_subnet.public-subnet2AZ2.id]

  
# }

# #listener
# resource "aws_lb_listener" "front-end" {
#   load_balancer_arn = aws_alb.alb-wordpress.id
#   port = "80"
#   protocol = "HTTP"

#   default_action {
#     type = "forward"
#     target_group_arn = aws_lb_target_group.target-alb.arn
#   }
  
# }
# #Target group
# resource "aws_lb_target_group" "target-alb" {
#   name = "alb-terraform-tg"
#   port = 80
#   protocol = "HTTP"
#   vpc_id = aws_vpc.main.id

#   health_check {
#     path = "/"
#     protocol = "HTTP"
#     matcher             = "200"
#     interval            = 30
#     timeout             = 5
#     healthy_threshold   = 3
#     unhealthy_threshold = 3
#   }
  
# }
# resource "aws_lb_target_group_attachment" "target-attach" {
#   target_group_arn = aws_lb_target_group.target-alb.arn
#   target_id = aws_instance.public-subnet1a.id
#   port = 80


  
# }

# resource "aws_lb_target_group_attachment" "target-attach2" {
#   target_group_arn = aws_lb_target_group.target-alb.arn
#   target_id = aws_instance.public-subnet2a.id
#   port = 80


  
# } 

# #alb sg
# resource "aws_security_group" "albsg" {
#     name = "alb-sg"
#   description = "allow HTTP and HTTPS traffiv to ALb"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port = 80
#     to_port = 80
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]

#   }
#    egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS traffic
  
# }
# }