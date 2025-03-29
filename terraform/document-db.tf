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
  name       = "${var.app_name}-docdb-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "${var.app_name}-docdb-subnet-group"
  }
}

resource "aws_docdb_cluster_parameter_group" "disable_tls" {
  family      = "docdb5.0"
  name        = "${var.app_name}-no-tls"
  description = "Disable TLS enforcement"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}

resource "aws_docdb_cluster" "main" {
  cluster_identifier              = "${var.app_name}-docdb-cluster"
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
  identifier         = "${var.app_name}-docdb-instance-${count.index}"
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = "db.t3.medium"
}
