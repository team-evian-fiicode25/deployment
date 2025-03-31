resource "helm_release" "main" {
  name       = "terraform-release"
  chart      = "../kubernetes"

  set {
    name  = "authentication.MONGO_URL"
    value = "mongodb://${aws_docdb_cluster.main.master_username}:${aws_docdb_cluster.main.master_password}@${aws_docdb_cluster.main.endpoint}:${aws_docdb_cluster.main.port}/?replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  }
}
