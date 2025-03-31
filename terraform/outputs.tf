output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "documentdb_connection" {
  value = {
    hostname = aws_docdb_cluster.main.endpoint
    username = aws_docdb_cluster.main.master_username
    password = aws_docdb_cluster.main.master_password
    port     = aws_docdb_cluster.main.port
  }
  sensitive = true
}

output "test_ec2" {
  value = {
    public_dns = aws_instance.test_ec2.public_dns
    public_ip  = aws_instance.test_ec2.public_ip
  }
}
