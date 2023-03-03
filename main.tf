provider "aws" {
  region = "us-east-1a"
  access_key = "AKIASGQRE7X6Q3AF5CYZ"
  secret_key = "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"
}


# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

#Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
}

#Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.2.0/24"
}
# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
}

#Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}


#Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Public RT"
  }
}
# associate public route table to public subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


#Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private RT"
  }
}
#Associate Private Route Table to Private Subnet
resource "aws_route_table_association" "private_rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}


#Security Group VM
resource "aws_security_group" "vm_sg" {
  name_prefix = "vm-sg"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
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

#VM in Private Subnet
resource "aws_instance" "vm" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name      = "pp-terraform"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.vm_sg.id]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y curl",
    ]
  }
}

output "vm_private_ip" {
  value = aws_instance.vm.private_ip
}
output "vm_public_ip" {
  value = aws_eip.nat_eip.public_ip
}



