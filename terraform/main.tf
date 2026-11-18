#------------------------------
#Configure aws provider
provider "aws" {
  region  = var.region
  profile = "x-streaming-lab"
}

#-----------------------------
#Read vpc resource 
data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = var.vpc_name
  }
}


#-----------------------------------------------
#Create  Elastic IP - Web Frontend

resource "aws_eip" "web" {
  domain = "vpc"

  tags = {
    Name = "gameofhackers-web-eip"
  }
}

resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}

output "web_elastic_ip" {
  value = aws_eip.web.public_ip
}

#------------------------------
#Create 2  subnets

resource "aws_subnet" "public" {
  vpc_id            = data.aws_vpc.this.id
  cidr_block        = var.public_cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.public_subnet_name
  }
}

resource "aws_subnet" "private" {
  vpc_id            = data.aws_vpc.this.id
  cidr_block        = var.private_cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.private_subnet_name
  }
}

#-----------------------------
# Create Key Pair


resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.module}/${var.key_name}.pem"
  file_permission = "0400"
}

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = tls_private_key.this.public_key_openssh
}


#-----------------------------
#Create Public Route Table

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "gameofhackers-nat-eip"
  }
}

resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = var.route_table_name
  }
}

#-------------------------------------------
# Associate public route table with public subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

#----------------------------------
#Create Gatway
resource "aws_internet_gateway" "this" {
  vpc_id = data.aws_vpc.this.id

  tags = {
    Name = "gameofhackers-igw"
  }
}

#----------------------------------------
# Security Group - Web Frontend (composant)

resource "aws_security_group" "web" {
  name   = "gameofhackers-web-sg"
  vpc_id = data.aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gameofhackers-web-sg"
  }
}
#------------------------------------
# Security Group - Web Fronted (régle)

resource "aws_security_group_rule" "ssh_to_web" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow SSH"
}

resource "aws_security_group_rule" "http_to_web" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP"
}

resource "aws_security_group_rule" "https_to_web" {
  type              = "ingress"
  security_group_id = aws_security_group.web.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS"
}

resource "aws_security_group_rule" "rtmp_to_web" {
  type                     = "ingress"
  security_group_id        = aws_security_group.web.id
  from_port                = 1935
  to_port                  = 1935
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.streamer.id
  description              = "Allow RTMP from Video Streamer"
}




#------------------------------------------
# Security Group - Video Streamer (composant)

resource "aws_security_group" "streamer" {
  name   = "gameofhackers-streamer-sg"
  vpc_id = data.aws_vpc.this.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gameofhackers-streamer-sg"
  }
}


#---------------------------------------------------------
# Security Group Rules - Video Streamer (Régle)

resource "aws_security_group_rule" "rtmp_to_streamer" {
  type                     = "ingress"
  security_group_id        = aws_security_group.streamer.id
  from_port                = 1935
  to_port                  = 1935
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  description              = "Allow RTMP from Web Frontend"
}

resource "aws_security_group_rule" "ssh_to_streamer" {
  type                     = "ingress"
  security_group_id        = aws_security_group.streamer.id
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web.id
  description              = "Allow SSH from Web Frontend"
}


#-----------------------------
# Elastic IP for NAT Gateway

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "gameofhackers-nat-gateway"
  }

  depends_on = [
    aws_internet_gateway.this
  ]
}

#-----------------------------
# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "gameofhackers-private-route-table"
  }
}

#-----------------------------
# Associate private route table with private subnet

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

#-----------------------------
# Read Ubuntu AMI

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

#-----------------------------
# Web Frontend EC2

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.web_instance_type

  subnet_id = aws_subnet.public.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]

  key_name = aws_key_pair.this.key_name

  iam_instance_profile = aws_iam_instance_profile.r53_devops.name

  associate_public_ip_address = true

  tags = {
    Name = var.web_instance_name
  }
}

#-----------------------------
# Video Streamer EC2

resource "aws_instance" "streamer" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.streamer_instance_type

  subnet_id = aws_subnet.private.id

  vpc_security_group_ids = [
    aws_security_group.streamer.id
  ]

  key_name = aws_key_pair.this.key_name


  associate_public_ip_address = false

  tags = {
    Name = var.streamer_instance_name
  }
}

#-----------------------------
# Outputs

output "web_public_ip" {
  value = aws_instance.web.public_ip
}

output "web_private_ip" {
  value = aws_instance.web.private_ip
}

output "streamer_private_ip" {
  value = aws_instance.streamer.private_ip
}

#-------------------------------
#Capture vpc_id in output variable
output "vpc_id" {
  value = data.aws_vpc.this.id
}

#Capture vpc_cidr_block in output variable
output "vpc_cidr_block" {
  value = data.aws_vpc.this.cidr_block
}
