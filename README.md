# InnovateMart Retail Store - EKS Deployment

## Project Overview
- EKS cluster with Terraform
- Microservices architecture
- AWS Load Balancer Controller (configuration attempted)
- IAM roles and policies

## Architecture
- VPC with public/private subnets
- EKS cluster with node groups
- Multiple microservices (UI, Catalog, Cart, Orders, Checkout)

## Access Instructions
```bash
kubectl port-forward svc/ui 8080:80

Then visit: http://localhost:8080

Challenges & Solutions
AWS Load Balancer Controller OIDC configuration issues

Used port-forward for application access

IAM roles and trust policies configured
