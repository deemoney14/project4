provider "aws" {
    region = "us-west-1"
  
}

#vpc

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "wordpress_vpc"
  }
}
# PubliC Subnet 1AZ
resource "aws_subnet" "public-subnet1AZ1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-1a"

    tags = {
      Name = "public-subnet1AZ1"
    }
  
}

resource "aws_subnet" "private-webserverAZ1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.32.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-west-1a"

    tags = {
      Name = "private-webserverAZ1"
    }
  
}

resource "aws_subnet" "private-rds-subnetAZ1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.16.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-west-1a"

    tags = {
      Name = "private-rds-subnetAZ1"
    }
  
}

#private subnet
resource "aws_subnet" "public-subnet2AZ2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-1c"

    tags = {
      Name = "public-subnet2AZ2"
    }
  
}

resource "aws_subnet" "private-webserverAZ2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.48.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-west-1c"

    tags = {
      Name = "private-webserverAZ1"
    }
  
}

resource "aws_subnet" "private-rds-subnetAZ2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.64.0/24"
    map_public_ip_on_launch = false
    availability_zone = "us-west-1c"

    tags = {
      Name = "private-rds-subnetAZ2"
    }
  
}

#igw
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
      Name = "igw"
    }
}
# route table Public
resource "aws_route_table" "pulic-rt" {
    vpc_id = aws_vpc.main.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "Public-rt"
    }
  
}
# route table private 
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main.id

  route = []

  tags = {
    Name = "private-rt"
  }
}

#local list of IP

locals {
  private_subnet = { 
    "subnet1" = aws_subnet.private-webserverAZ1.id,
    "subnet2" = aws_subnet.private-rds-subnetAZ1.id,
    "subnet3" = aws_subnet.private-rds-subnetAZ2.id, 
    "subnet4" = aws_subnet.private-webserverAZ2.id    
  }
}
#route table association
#Public 1
resource "aws_route_table_association" "public-assoc" {
    subnet_id = aws_subnet.public-subnet1AZ1.id
    route_table_id = aws_route_table.pulic-rt.id
 
}
#public 2
resource "aws_route_table_association" "public-assoc1a" {
    subnet_id = aws_subnet.public-subnet2AZ2.id
    route_table_id = aws_route_table.pulic-rt.id
 
}
# Private
resource "aws_route_table_association" "private-assoc"{
    subnet_id = each.value
    route_table_id = aws_route_table.private-rt.id
    for_each = local.private_subnet
  
}
#key name
resource "aws_key_pair" "bash" {
  key_name = "bash-key"
  public_key = file("bash.pem.pub")
  
}


# Bastion Host
resource "aws_instance" "bastion-host" {
  ami = "ami-04fdea8e25817cd69"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet1AZ1.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]
  key_name = aws_key_pair.bash.key_name
  
  tags = {
    Name = "bashtion-host"
  }
}
# sg for bs
resource "aws_security_group" "bastion-sg" {
  name = "bastion-sg"
  description = "allow ssh to the bastion host"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "bastion-sg"
  }
}


# word press on pv instance
resource "aws_instance" "wordpress" {
  ami = "ami-04fdea8e25817cd69"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private-webserverAZ1.id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.wordpress-sg.id]
  key_name = aws_key_pair.bash.key_name

user_data = <<-EOF
            #!/bin/bash
            apt update -y
            apt install -y apache2 php libapache2-mod-php php-mysql
            systemctl start apache2
            systemctl enable apache2
            EOF


  tags = {
    Name = "wordpress-pv"
  } 
}

 resource "aws_instance" "wordpress2" {
  ami = "ami-04fdea8e25817cd69"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private-webserverAZ2.id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.wordpress-sg.id]
  key_name = aws_key_pair.bash.key_name

user_data = <<-EOF
            #!/bin/bash
            apt update -y
            apt install -y apache2 php libapache2-mod-php php-mysql
            systemctl start apache2
            systemctl enable apache2
            EOF


  tags = {
    Name = "wordpress-pv2"
  } 
  }


#sg for wordpress
resource "aws_security_group" "wordpress-sg" {
  name = "wordpress-sg"
  description = "allow access wordserver from bastion"
  vpc_id = aws_vpc.main.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-sg"
  }
  }
  # Allow HTTP traffic from the ALB
resource "aws_security_group_rule" "http_from_alb" {
  type                      = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.wordpress-sg.id
  source_security_group_id  = aws_security_group.alb-sg.id
}

# Allow SSH traffic only from Bastion Host
resource "aws_security_group_rule" "ssh_from_bastion" {
  type                      = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.wordpress-sg.id
  source_security_group_id  = aws_security_group.bastion-sg.id
}


#alb 
resource "aws_lb" "word" {
  name = "word-alb-tf"
  internal = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.alb-sg.id]
  subnets = [aws_subnet.public-subnet1AZ1.id, aws_subnet.public-subnet2AZ2.id]
  
}
#target group
resource "aws_lb_target_group" "wordpress-tg" {
  name = "wordpress-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.main.id


   health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  
}
}
#alb listener

resource "aws_lb_listener" "wordpress-listener" {
  load_balancer_arn = aws_lb.word.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.wordpress-tg.arn

  }
  
}

# Register the WordPress instance1 with the Target Group
resource "aws_lb_target_group_attachment" "wordpress-tg-attachment" {
  target_group_arn = aws_lb_target_group.wordpress-tg.arn
  target_id        = aws_instance.wordpress.id
  port             = 80
}

# Register the second WordPress instance with the Target Group
resource "aws_lb_target_group_attachment" "wordpress-tg-attachment2" {
  target_group_arn = aws_lb_target_group.wordpress-tg.arn
  target_id        = aws_instance.wordpress2.id
  port             = 80
}

#alb sg
resource "aws_security_group" "alb-sg" {
  name = "alb-sg"
  description = "allow HTTP and HTTPS traffiv to ALb"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
   egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS traffic
  }

}
#rds
