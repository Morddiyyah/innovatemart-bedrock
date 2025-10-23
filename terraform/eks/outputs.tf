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
