terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83.0"
    }
  }
  backend "s3" {
    bucket = "terraform-rideme"
    key    = "terraform.key"
    region = "eu-central-1"
  }
}

provider "aws" {
  region = "eu-central-1"
}

locals {
  app_name     = "rideme"
  cluster_name = "rideme-${random_string.suffix.result}"
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_budgets_budget" "budget" {
  name              = "monthly-budget"
  budget_type       = "COST"
  limit_amount      = "30.0"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2024-03-15_00:01"
}

data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${local.app_name}-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = local.cluster_name
  cluster_version = "1.31"

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    one = {
      name = "ng-1"

      instance_types = ["t2.small"]

      min_size     = 1
      max_size     = 4
      desired_size = 2
    }
  }
}

resource "aws_security_group" "document_db_sg" {
  name        = "document_db_sg"
  description = "Allow mongo traffic from the private subnet"
  vpc_id      = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = module.vpc.private_subnets_cidr_blocks
    content {
      description = "Allow MongoDB from private subnet ${ingress.key}"
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  tags = {
    Name = "document_db_sg"
  }
}

resource "aws_docdb_subnet_group" "main" {
  name       = "${local.app_name}-docdb-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${local.app_name}-docdb-subnet-group"
  }
}

resource "aws_docdb_cluster_parameter_group" "disable_tls" {
  family      = "docdb5.0"
  name        = "${local.app_name}-no-tls"
  description = "Disable TLS enforcement"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${local.app_name}-docdb-cluster"
  engine                          = "docdb"
  master_username                 = "root"
  master_password                 = var.document_db_password
  backup_retention_period         = 1
  preferred_backup_window         = "07:00-09:00"
  skip_final_snapshot             = true
  db_subnet_group_name            = aws_docdb_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.document_db_sg.id]
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.disable_tls.name

  engine_version      = "5.0.0"
  storage_encrypted   = true
  deletion_protection = false

  lifecycle {
    ignore_changes = [availability_zones]
  }
}

resource "aws_docdb_cluster_instance" "main" {
  count              = 1
  identifier         = "${local.app_name}-docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"
}

output "documentdb_connection" {
  value = {
    endpoint = aws_docdb_cluster.main.endpoint
    username = aws_docdb_cluster.main.master_username
  }
  sensitive = true
}
