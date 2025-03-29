output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "documentdb_connection" {
  value = {
    endpoint = aws_docdb_cluster.main.endpoint
    username = aws_docdb_cluster.main.master_username
  }
  sensitive = true
}
