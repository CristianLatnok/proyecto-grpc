# Crea una VPC
resource "aws_vpc" "vpc_eks" {
  cidr_block = "10.0.0.0/16"
}

# Crea una subnet pública
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.vpc_eks.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"  # Cambia esto a tu zona de disponibilidad preferida

  tags = {
    Name = "Public Subnet"
  }
}

# Crea una subnet privada
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc_eks.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"  # Cambia esto a tu zona de disponibilidad preferida

  tags = {
    Name = "Private Subnet"
  }
}

# Configura la tabla de ruteo para la subnet pública
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc_eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_eks.id
  }
}

# Asocia la subnet pública a la tabla de ruteo pública
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Crea una puerta de enlace de internet
resource "aws_internet_gateway" "igw_eks" {
  vpc_id = aws_vpc.vpc_eks.id
}

# Configura la tabla de ruteo para la subnet privada
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc_eks.id
}

# Asocia la subnet privada a la tabla de ruteo privada
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}
