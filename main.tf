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
#Create NAT GATEWAY EIP
resource "aws_eip" "nat-eip" {
  
  
}
# GATEWAY 1
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat-eip.id
  subnet_id = aws_subnet.public-subnet1AZ1.id

  tags = {
    Name = "nat-gateway1"
  }

}
#Create NAT GATEWAY EIP
resource "aws_eip" "nat-eip2" {
  
}

# GATEWAY 2
resource "aws_nat_gateway" "nat2" {
  allocation_id = aws_eip.nat-eip2.id
  subnet_id = aws_subnet.public-subnet2AZ2.id

  tags = {
    Name = "nat-gateway2"
  }


}

# route table Public
resource "aws_route_table" "public-rt" {
    vpc_id = aws_vpc.main.id

    route{
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
      Name = "Public-rt"
    }

}

#Private Route with Nat Gateway
#Private 1
resource "aws_route_table" "private-web-rt1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat1.id
  }

  tags = {
    Name = "private-web-rt1"
  }
  
}
#Private 2
resource "aws_route_table" "private-web-rt2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat2.id
  }
  
  tags = {
    Name = "private-web-rt2"
  }
  
}

#route table association
#Public 1
resource "aws_route_table_association" "public-assoc" {
    subnet_id = aws_subnet.public-subnet1AZ1.id
    route_table_id = aws_route_table.public-rt.id

}
#public 2
resource "aws_route_table_association" "public-assoc1a" {
    subnet_id = aws_subnet.public-subnet2AZ2.id
    route_table_id = aws_route_table.public-rt.id

}


#Private 1
resource "aws_route_table_association" "private-assoc" {
  subnet_id = aws_subnet.private-webserverAZ1.id
  route_table_id = aws_route_table.private-web-rt1.id
  
}
#Private 2
resource "aws_route_table_association" "private-assoc2" {
  subnet_id = aws_subnet.private-webserverAZ2.id
  route_table_id = aws_route_table.private-web-rt2.id

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

resource "aws_instance" "bastion-host2" {
  ami = "ami-04fdea8e25817cd69"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public-subnet2AZ2.id
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.bastion-sg.id]
  key_name = aws_key_pair.bash.key_name

  tags = {
    Name = "bashtion-host2"
  }
}
# sg for bs
resource "aws_security_group" "bastion-sg" {
  name = "bastion-sg"
  description = "allow ssh to the bastion host"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
              yum update -y
              yum install -y httpd
              yum install -y php php-mysqlnd
              amazon-linux-extras install -y php7.4
              systemctl start httpd
              systemctl enable httpd
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
              yum update -y
              yum install -y httpd
              yum install -y php php-mysqlnd
              amazon-linux-extras install -y php7.4
              systemctl start httpd
              systemctl enable httpd
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
    healthy_threshold   = 3
    unhealthy_threshold = 3

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
output "alb_dns_name" {
  value = aws_lb.word.dns_name
  
}
#rds
resource "aws_db_instance" "db_instance" {
  allocated_storage = 100
  engine = "mysql"
  engine_version = "8.0.34"
  instance_class = "db.t3.micro"
  username = "Admin"
  password = "sam12312"
  vpc_security_group_ids = [aws_security_group.rds-sg.id]
  multi_az = false
  publicly_accessible = false 
  db_subnet_group_name = aws_db_subnet_group.wordpress-db.name
  skip_final_snapshot = true 
  db_name = "wordpressdb"
  identifier = "wordpress-db"

  tags = {
    Name = "wordpress-db"
  }

}

#RDS Subent Group
resource "aws_db_subnet_group" "wordpress-db" {
  name = "wordpress-db-subnet-group"
  subnet_ids = [aws_subnet.private-rds-subnetAZ1.id, aws_subnet.private-rds-subnetAZ2.id]

  tags = {
    Name = "wordpress-db-subnet-group"
  }
  
}

#rds SG

resource "aws_security_group" "rds-sg" {
  name = "rds-sg"
  description = "Allow MySQL access from WordPress instances"
  vpc_id      = aws_vpc.main.id

  # ingress = {
  #   from_port = 3306
  #   to_port = 3306
  #   protocol = "tcp"
  #   security_groups = [aws_security_group.wordpress_sg.id]
  # }

  egress  {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
  
}

resource "aws_security_group_rule" "rds-sg1" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  security_group_id = aws_security_group.rds-sg.id
  source_security_group_id = aws_security_group.wordpress-sg.id
  
}