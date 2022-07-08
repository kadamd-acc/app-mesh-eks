
/*=========
The VPC
===========*/

resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.vpc_name}-${var.environment}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"  # Refer: https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
    Environment = var.environment
    Group = var.cluster_group
  }
}


/*================
Public Subnets
==================*/

 resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = element(var.public_subnets_cidr, count.index)
  availability_zone = element(var.availability_zones_public, count.index)
  count = length(var.public_subnets_cidr)
  map_public_ip_on_launch  = true
  depends_on = [aws_vpc.main_vpc]

  tags = {
    Name        = substr("public-subnet-${var.environment}-${element(var.availability_zones_public, count.index)}",0,64)
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
    Environment = var.environment
    Group = var.cluster_group
  }
}


/*================
Private Subnets
==================*/

 resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = element(var.private_subnets_cidr, count.index)
  availability_zone = element(var.availability_zones_private, count.index)
  count = length(var.private_subnets_cidr)
  map_public_ip_on_launch  = false
  depends_on = [ aws_vpc.main_vpc ]

  tags = {
    Name        = substr("private-subnet-${var.environment}-${element(var.availability_zones_private, count.index)}",0,64)
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}" = "shared"
    Environment = var.environment
    Group = var.cluster_group
  }
}

/*=================
Internet Gateway
===================*/
/* Internet gateway for the public subnet */

resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.main_vpc.id
  depends_on = [aws_subnet.public_subnet]

  tags = {
    Name        = substr("internet_gw-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}

/* ===================
Elastic IP(s) for NAT 
====================*/

resource "aws_eip" "nat_eip" {
  vpc        = true
  count = length(var.private_subnets_cidr)
  public_ipv4_pool = "amazon"
  depends_on = [aws_internet_gateway.internet_gw]

    tags = {
    Name        = substr("nat-ip-${count.index + 1}-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}

/*=================
NAT Gateway(s)
=================*/

# Creating NAT Gateways based on Public Subnets.
#For High Availibility each Public Subnect will have one NAT Gateway

resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.private_subnets_cidr)
  allocation_id = element(aws_eip.nat_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)
  depends_on    = [aws_internet_gateway.internet_gw,aws_eip.nat_eip]

  tags = {
    Name = substr("nat_gateway-${count.index + 1}-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}

/*===============================
Routing table for public subnet 
================================*/

# Creating One Route Table for all the Public Subnets.

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  depends_on = [aws_subnet.public_subnet ]

  tags = {
    Name = substr("public-route-table-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}

# Public route table entry for internet route 
resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = var.cidr_block_internet_gw
  gateway_id             =  aws_internet_gateway.internet_gw.id

  depends_on = [aws_route_table.public_rt , aws_subnet.public_subnet]

}

# Route table associations for public subnets
resource "aws_route_table_association" "public-rt-assotion" {
  count = length(var.public_subnets_cidr)
  subnet_id  =  element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id

    depends_on = [aws_route_table.public_rt , aws_route.public_internet_route]
}


/* ==================================
Routing table(s) for private subnets 
====================================*/

# Creating Multiple Route Tables as per the Private Subnets. 
# Each Private Subnet will have individual Route Table.

resource "aws_route_table" "private_rt" {
  count  = length(var.private_subnets_cidr)
  vpc_id = element(aws_vpc.main_vpc.*.id, count.index)
  depends_on = [aws_subnet.private_subnet]

  tags = {
    Name = substr("private-route-table-${count.index + 1}-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}

# Private route table entry for nat gateway route #
resource "aws_route" "private_nat_gw_route" {
  count  = length(var.private_subnets_cidr)
  route_table_id         = element(aws_route_table.private_rt.*.id, count.index)
  destination_cidr_block = var.cidr_block_nat_gw
  gateway_id             =  element(aws_nat_gateway.nat_gw.*.id, count.index)

  depends_on = [aws_route_table.private_rt , aws_subnet.private_subnet]
}


# Route table associations for private subnets 
resource "aws_route_table_association" "private-rt-assotion" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt.*.id, count.index)
 
    depends_on = [aws_route.private_nat_gw_route , aws_route_table.private_rt]
}


/*============================
VPC's Security Group(s)
=============================*/

# Updating the default security group with no inbound and outbound to internet
  resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    protocol  = "-1"
    self      = true
    from_port = 0
    to_port   = 0
  }
   ingress {
    protocol  = "TCP"
    self      = true
    from_port = 80
    to_port   = 80
    cidr_blocks =["35.177.235.44/32",
                      "35.177.241.232/32",
    "165.225.80.0/22",
    "42.200.32.9/32",
    "134.159.88.9/32",
    "165.225.76.0/23",
    "34.195.146.191/32",
    "194.63.116.0/24",   
    "194.63.110.0/24",   
    "194.63.66.0/23",    
    "194.63.68.0/23",    
    "195.27.188.4/32",   
    "195.89.14.2/32",    
    "195.89.226.240/29", 
    "193.200.176.0/24",  
    "42.200.32.0/26",    
    "134.159.88.0/26",   
    "216.1.124.192/27",  
    "50.218.78.0/24",    
    "50.230.37.128/29",  
    "51.11.59.26/32",    
    "51.11.25.210/32",   
    "51.137.143.189/32", 
    "51.137.137.183/32", 
    "51.104.248.9/32",   
    "51.11.123.193/32",  
    "20.189.117.30/32",  
    "52.237.89.178/32",  
    "52.141.169.190/32", 
    "52.185.227.209/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = substr("default-sg-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}

# Custom security group with few inbound rules and outbound to internet
resource "aws_security_group" "custom" {
  name        = substr("custom-sg-${var.cluster_name}-${var.environment}",0,64)
  description = "Custom security group to allow inbound/outbound from the multiple sources"
  vpc_id      = aws_vpc.main_vpc.id
  depends_on  = [aws_vpc.main_vpc]

  ingress {
    description   = "Receive traffic from internet on HTTP Port 80"
    from_port = "80"
    to_port   = "80"
    cidr_blocks = ["0.0.0.0/0"]
    protocol  = "tcp"
  }

  ingress {
    description   = "Receive traffic from internet on TLS Port 443"
    from_port = "443"
    to_port   = "443"
    cidr_blocks = ["0.0.0.0/0"]
    protocol  = "tcp"
  }

  egress {
    description = "All traffic allowed to Internet from VPC"
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }

  tags = {
    Name = substr("custom-sg-${var.cluster_name}-${var.environment}",0,64)
    Environment = var.environment
    Group = var.cluster_group
  }
}




