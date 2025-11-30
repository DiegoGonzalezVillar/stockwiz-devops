data "aws_availability_zones" "available" {}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project_name}-${var.env}-vpc"
    Project     = var.project_name
    Environment = var.env
  }
}

# INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.env}-igw"
  }
}

# PUBLIC SUBNETS (2)
resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "stockwiz-${terraform.workspace}-public-${count.index}"
  }
}

# PUBLIC ROUTE TABLE
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.env}-public-rt" 
  }
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# PRIVATE SUBNETS 
resource "aws_subnet" "private_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index + 2) # Usamos índices 2 y 3
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false # ¡Es clave que sea FALSE!

  tags = {
    Name = "stockwiz-${terraform.workspace}-private-${count.index}"
  }
}

# NAT GATEWAY & ELASTIC IP
resource "aws_eip" "nat" {
  count = 2
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id

  tags = {
    Name = "stockwiz-${terraform.workspace}-nat-${count.index}"
  }
}

# Tablas de Enrutamiento PRIVADAS
resource "aws_route_table" "private_rt" {
  count  = 2
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.project_name}-${var.env}-private-rt-${count.index}" # ⬅️ Agregar este tag
  }
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }
}

# Asociación de Rutas Privadas
resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt[count.index].id
}


# ALB security group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${terraform.workspace}"
  description = "Allow inbound HTTP"
  vpc_id      = aws_vpc.main.id

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

# ECS Tasks SG
resource "aws_security_group" "ecs_sg" {
  name        = "ecs-sg-${terraform.workspace}"
  description = "Allow traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

