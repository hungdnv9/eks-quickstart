# -----------------------
# Infrastructure - Cores
# ------------------------

## create & configuire vpc
resource "aws_vpc" "vpc_01" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc_01"
  }
}

## create & configure public/private subnet
resource "aws_subnet" "vpc_01_public_snet_ap_north_1a" {
  cidr_block              = "10.0.1.0/24"
  vpc_id                  = aws_vpc.vpc_01.id
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "vpc_01_public_snet_ap_north_1a",
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "vpc_01_public_snet_ap_north_1c" {
  cidr_block              = "10.0.3.0/24"
  vpc_id                  = aws_vpc.vpc_01.id
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true
  tags = {
    Name                     = "vpc_01_public_snet_ap_north_1c",
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_subnet" "vpc_01_private_snet_ap_north_1a" {
  cidr_block              = "10.0.2.0/24"
  vpc_id                  = aws_vpc.vpc_01.id
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false
  tags = {
    Name                              = "vpc_01_private_snet_ap_north_1a",
    "kubernetes.io/role/internal-elb" = 1
  }
}

resource "aws_subnet" "vpc_01_private_snet_ap_north_1c" {
  cidr_block              = "10.0.4.0/24"
  vpc_id                  = aws_vpc.vpc_01.id
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false
  tags = {
    Name                              = "vpc_01_private_snet_ap_north_1c",
    "kubernetes.io/role/internal-elb" = 1
  }
}

## create & configure igw
resource "aws_internet_gateway" "vpc_01_igw" {
  vpc_id = aws_vpc.vpc_01.id

  tags = {
    Name = "vpc_01_igw"
  }
}

## create & configure natgw
resource "aws_eip" "vpc_01_natgw_eip" {
  vpc = true

  tags = {
    Name = "vpc_01_natgw_eip"
  }
}

resource "aws_nat_gateway" "vpc_01_natgw" {
  allocation_id = aws_eip.vpc_01_natgw_eip.id
  subnet_id     = aws_subnet.vpc_01_public_snet_ap_north_1a.id

  tags = {
    Name = "vpc_01_natgw"
  }
}

## create & configure route table
resource "aws_route_table" "vpc_01_public_rtb" {
  vpc_id = aws_vpc.vpc_01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_01_igw.id
  }

  tags = {
    Name = "vpc_01_public_rtb"
  }
}

resource "aws_route_table_association" "vpc_01_public_snet_ap_north_1a" {
  subnet_id      = aws_subnet.vpc_01_public_snet_ap_north_1a.id
  route_table_id = aws_route_table.vpc_01_public_rtb.id
}

resource "aws_route_table_association" "vpc_01_public_snet_ap_north_1c" {
  subnet_id      = aws_subnet.vpc_01_public_snet_ap_north_1c.id
  route_table_id = aws_route_table.vpc_01_public_rtb.id
}

//

resource "aws_route_table" "vpc_01_private_rtb" {
  vpc_id = aws_vpc.vpc_01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.vpc_01_natgw.id
  }

  tags = {
    Name = "vpc_01_private_rtb"
  }
}


resource "aws_route_table_association" "vpc_01_private_snet_ap_north_1a" {
  subnet_id      = aws_subnet.vpc_01_private_snet_ap_north_1a.id
  route_table_id = aws_route_table.vpc_01_private_rtb.id
}

resource "aws_route_table_association" "vpc_01_private_snet_ap_north_1c" {
  subnet_id      = aws_subnet.vpc_01_private_snet_ap_north_1c.id
  route_table_id = aws_route_table.vpc_01_private_rtb.id
}

/* Terraform Outputs */

output "vpc_id" {
  value = aws_vpc.vpc_01.id
}
