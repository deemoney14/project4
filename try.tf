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
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id

    tags = {
      Name = "igw"
    }
}
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

locals {
    public_sub = {
        "subnet1" = aws_subnet.public-subnet1AZ1.id,
        "subnet2" = aws_subnet.public-subnet2AZ2.id
    }
 

}

locals {
  private_subnet = {
    "subnet1" = aws_subnet.private-webserverAZ1.id,
    "subnet2" = aws_subnet.private-webserverAZ2.id
  }
}
resource "aws_route_table_association" "public-assoc" {
    subnet_id = aws_subnet.public-subnet1AZ1.id
    route_table_id = aws_route_table.pulic-rt.id

  
}

resource "aws_route_table_association" "public-assoc2" {
    subnet_id = aws_subnet.public-subnet1AZ1.id
    route_table_id = aws_route_table.pulic-rt.id
    
  
}