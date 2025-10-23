# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# VPC and Networking
# -----------------------------------------------------------------------------
resource "aws_vpc" "innovatemart_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "innovatemart_igw" {
  vpc_id = aws_vpc.innovatemart_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_eip" "nat_gateway_eip" {
  count = length(var.public_subnet_cidrs)
  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "innovatemart_nat_gateway" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat_gateway_eip[count.index].id
  subnet_id     = aws_subnet.innovatemart_public_subnet[count.index].id

  tags = {
    Name = "${var.cluster_name}-nat-gateway-${count.index}"
  }
  depends_on = [aws_internet_gateway.innovatemart_igw]
}

resource "aws_subnet" "innovatemart_public_subnet" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.innovatemart_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb"                      = "1" # For AWS Load Balancer Controller
  }
}

resource "aws_subnet" "innovatemart_private_subnet" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.innovatemart_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.cluster_name}-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb"             = "1" # For AWS Load Balancer Controller
  }
}

resource "aws_route_table" "innovatemart_public_rt" {
  vpc_id = aws_vpc.innovatemart_vpc.id

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_route" "innovatemart_public_internet_route" {
  route_table_id         = aws_route_table.innovatemart_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.innovatemart_igw.id
}

resource "aws_route_table_association" "innovatemart_public_rt_association" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.innovatemart_public_subnet[count.index].id
  route_table_id = aws_route_table.innovatemart_public_rt.id
}

resource "aws_route_table" "innovatemart_private_rt" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.innovatemart_vpc.id

  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index}"
  }
}

resource "aws_route" "innovatemart_private_nat_route" {
  count                  = length(var.private_subnet_cidrs)
  route_table_id         = aws_route_table.innovatemart_private_rt[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.innovatemart_nat_gateway[count.index].id
}

resource "aws_route_table_association" "innovatemart_private_rt_association" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.innovatemart_private_subnet[count.index].id
  route_table_id = aws_route_table.innovatemart_private_rt[count.index].id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# -----------------------------------------------------------------------------
# EKS Cluster IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_service_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# -----------------------------------------------------------------------------
# EKS Node Group IAM Role
# -----------------------------------------------------------------------------
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.cluster_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

# -----------------------------------------------------------------------------
# EKS Cluster
# -----------------------------------------------------------------------------
resource "aws_eks_cluster" "innovatemart_eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29" # Updated to 1.29 as discussed

  vpc_config {
    subnet_ids         = concat(aws_subnet.innovatemart_public_subnet[*].id, aws_subnet.innovatemart_private_subnet[*].id)
    security_group_ids = [] # EKS creates a security group by default
  }

  tags = {
    Name = var.cluster_name
  }

  # Ensure that IAM Role for EKS Cluster is created before EKS Cluster
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_service_policy,
  ]
}

# -----------------------------------------------------------------------------
# EKS Managed Node Group
# -----------------------------------------------------------------------------
resource "aws_eks_node_group" "innovatemart_node_group" {
  cluster_name    = aws_eks_cluster.innovatemart_eks_cluster.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = aws_subnet.innovatemart_private_subnet[*].id # Use private subnets for nodes
  instance_types  = [var.instance_type]

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  tags = {
    Name = "${var.cluster_name}-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ec2_container_registry_read_only,
  ]
}

# -----------------------------------------------------------------------------
# RDS for PostgreSQL (Orders Service)
# -----------------------------------------------------------------------------
resource "aws_db_instance" "orders_db" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.4" # Choose an appropriate version
  instance_class       = "db.t3.micro" # Or a larger instance type
  db_name              = "ordersdb"
  username             = "ordersuser"
  password             = "YOUR_ORDERS_DB_PASSWORD" # REPLACE THIS WITH A SECURE PASSWORD!
  port                 = 5432
  publicly_accessible  = false
  multi_az             = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  tags = {
    Name = "${var.cluster_name}-orders-db"
  }
}

# -----------------------------------------------------------------------------
# RDS for MySQL (Catalog Service)
# -----------------------------------------------------------------------------
resource "aws_db_instance" "catalog_db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.4.6" # Choose an appropriate version
  instance_class       = "db.t3.micro" # Or a larger instance type
  db_name              = "catalogdb"
  username             = "cataloguser"
  password             = "YOUR_CATALOG_DB_PASSWORD" # REPLACE THIS WITH A SECURE PASSWORD!
  port                 = 3306
  publicly_accessible  = false
  multi_az             = false
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name

  tags = {
    Name = "${var.cluster_name}-catalog-db"
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Table (Cart Service)
# -----------------------------------------------------------------------------
resource "aws_dynamodb_table" "cart_table" {
  name           = "${var.cluster_name}-cart-table"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.cluster_name}-cart-table"
  }
}

# -----------------------------------------------------------------------------
# DB Subnet Group and Security Group for RDS
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = aws_subnet.innovatemart_private_subnet[*].id # Use private subnets for RDS

  tags = {
    Name = "${var.cluster_name}-db-subnet-group"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.cluster_name}-db-sg"
  description = "Allow inbound traffic to RDS instances from EKS nodes"
  vpc_id      = aws_vpc.innovatemart_vpc.id

  ingress {
    from_port   = 5432 # PostgreSQL
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_eks_cluster.innovatemart_eks_cluster.vpc_config[0].cluster_security_group_id] # From EKS Cluster SG
  }

  ingress {
    from_port   = 3306 # MySQL
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_eks_cluster.innovatemart_eks_cluster.vpc_config[0].cluster_security_group_id] # From EKS Cluster SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-db-sg"
  }
}
