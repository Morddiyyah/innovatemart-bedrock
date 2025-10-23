output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.innovatemart_eks_cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint for the EKS cluster"
  value       = aws_eks_cluster.innovatemart_eks_cluster.endpoint
}

output "kubeconfig_command" {
  description = "Command to update your kubeconfig"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.innovatemart_eks_cluster.name}"
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.innovatemart_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.innovatemart_public_subnet[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.innovatemart_private_subnet[*].id
}

output "orders_db_endpoint" {
  description = "Endpoint for the Orders PostgreSQL database"
  value       = aws_db_instance.orders_db.address
}

output "catalog_db_endpoint" {
  description = "Endpoint for the Catalog MySQL database"
  value       = aws_db_instance.catalog_db.address
}

output "cart_dynamodb_table_name" {
  description = "Name of the Cart DynamoDB table"
  value       = aws_dynamodb_table.cart_table.name
}
