Project Bedrock: InnovateMart Retail Store Application on AWS EKS

Deliverables

APP URL: http://localhost:8080/
The intended public access via AWS Application Load Balancer is currently experiencing an `InvalidIdentityToken: Incorrect token audience` error due in the EKS Node Group IAM Role's Trust Policy, preventing the ALB and Classic Load Balancer from provisioning.

    **Temporary Local Access (kubectl port-forward):**
    i can access the `ui` application locally for demonstration and testing purposes.
Attached below are images to prove it worked

![Alt text](https://github.com/Morddiyyah/innovatemart-bedrock/blob/bbf78c69ee64986546510fd57c559a47d4fa63ee/Screenshot%202025-10-24%20045341.png)

![Alt text]()
Git Repository Link: [https://github.com/Darkchild123/innovatemart-bedrock.git] Deployment & Architecture Guide: This README serves as a comprehensive guide. * Architecture Overview: (Describe the microservices architecture, how services communicate, and the EKS components used). * Application Access: Refer to the "Accessing the Application" section above. * Developer Credentials: Refer to the "Developer Access Instructions" section above.

Overview

Screenshot 2025-10-06 144630

File structure

retail-store-sample-app/ ├── .github/ # GitHub Actions workflows for CI/CD ├── docs/ # Project documentation and diagrams ├── oss/ # Open Source Software attribution and tools ├── samples/ # Sample data (products, tags) and images ├── scripts/ # Various utility scripts (build, deploy, generate reports) ├── src/ # Main source code directory │ ├── app/ # Application-level configurations & Helm charts │ │ ├── chart/ # Main Helm chart for the entire application │ │ ├── compose.override.yaml # Docker Compose override file │ │ ├── docker-compose.yml # Docker Compose definition for local dev │ │ └── templates/ # Helm chart templates │ ├── cart/ # Shopping Cart Microservice (Java) │ │ ├── chart/ # Helm chart for the cart service │ │ ├── Dockerfile │ │ ├── openapi.yml │ │ ├── pom.xml # Maven project file │ │ └── src/ # Java source code │ ├── catalog/ # Product Catalog Microservice (Go) │ │ ├── api/ # Go API definitions │ │ ├── chart/ # Helm chart for the catalog service │ │ ├── config/ │ │ ├── controller/ │ │ ├── Dockerfile │ │ ├── go.mod # Go module file │ │ ├── main.go # Main Go application entry point │ │ ├── model/ │ │ ├── openapi.yml │ │ └── repository/ │ ├── checkout/ # Checkout Microservice (TypeScript/Node.js) │ │ ├── chart/ # Helm chart for the checkout service │ │ ├── Dockerfile │ │ ├── package.json # Node.js package file │ │ ├── openapi.yml │ │ └── src/ # TypeScript/JavaScript source code │ ├── e2e/ # End-to-End Tests (Cypress/JavaScript) │ │ ├── cypress/ │ │ ├── cypress.config.js │ │ └── package.json │ ├── load-generator/ # Load Generation Tool │ │ ├── Dockerfile │ │ ├── package.json │ │ └── scenario.yml │ ├── orders/ # Orders Microservice (Java) │ │ ├── chart/ # Helm chart for the orders service │ │ ├── Dockerfile │ │ ├── events/ # Event definitions │ │ ├── openapi.yml │ │ ├── pom.xml │ │ └── src/ # Java source code │ └── ui/ # User Interface / Frontend (Java/Spring Boot/Thymeleaf) │ ├── chart/ # Helm chart for the UI service │ ├── Dockerfile │ ├── pom.xml │ └── src/ # Java, HTML, static assets └── terraform/ # Infrastructure as Code (IaC) with Terraform ├── apprunner/ # Terraform for AWS App Runner deployment ├── ecs/ # Terraform for AWS ECS deployment ├── eks/ # Terraform for AWS EKS deployment │ └── default/ # Default EKS cluster configuration └── lib/ # Reusable Terraform modules ├── CHANGELOG.md ├── CODE_OF_CONDUCT.md ├── CONTRIBUTING.md ├── DEVELOPER_GUIDE.md ├── devenv.lock ├── devenv.nix ├── devenv.yaml ├── LICENSE ├── nx.json # Nx Monorepo configuration ├── package.json ├── README.md ├── release-please-config.json ├── renovate.json └── yarn.lock

This repository contains the infrastructure as code (IaC) and application deployment configurations for "Project Bedrock," InnovateMart Inc.'s mission to deploy its new microservices-based retail store application to a production-grade Kubernetes environment on AWS. As the Cloud DevOps Engineer, my objective was to establish a scalable and automated foundation for the application on Amazon Elastic Kubernetes Service (EKS).

The retail-store-sample-app is a polyglot microservices application, designed for resilience and scalability, and deployed using modern DevOps practices.

Core Requirements Implemented

1. Infrastructure as Code (IaC)

All necessary AWS resources are provisioned using Terraform. The IaC defines:

A Virtual Private Cloud (VPC) with public and private subnets.
An Amazon EKS cluster named retail-store in the eu-west-2 region.
Necessary IAM roles and policies for the EKS cluster and node groups.
The Terraform configurations are located in the terraform/eks/default directory.

2. Application Deployment

The retail-store-sample-app is deployed to the EKS cluster using Helm. For this initial deployment, all in-cluster dependencies (databases like MySQL, PostgreSQL, DynamoDB Local; and message brokers like Redis, RabbitMQ) are running as containers within the EKS cluster.

The main application Helm chart is located in src/app/chart.

3. Developer Access

A new IAM user, innovatemart-dev-readonly, has been created with read-only access to the resources within the EKS cluster. This allows developers to view logs, describe pods, and check service status without the ability to make modifications.

4. Automation with CI/CD

A CI/CD pipeline, implemented using GitHub Actions, automates the deployment of the Terraform infrastructure code. The pipeline adheres to a sound branching strategy (e.g., GitFlow inspired), where:

Pushes to feature branches trigger a "terraform plan".
Merges to the main branch trigger a "terraform apply". AWS credentials are securely managed using GitHub Secrets and are not hardcoded in the pipeline configuration.
Deployment Steps (High-Level)

This section outlines the manual steps to deploy, assuming an Ubuntu environment. For automated deployments, refer to the GitHub Actions workflow.

Prerequisites

Ensure the following tools are installed on your Ubuntu machine:

AWS CLI
Terraform
kubectl
Helm
AWS CLI Configuration

Configure your AWS CLI with appropriate administrator credentials:

bash command aws configure

1. Deploy EKS Infrastructure with Terraform

Navigate to the Terraform EKS directory and apply the configuration.

bash commands cd terraform/eks/default terraform init terraform plan terraform apply --auto-approve

2. Configure kubectl

Update your kubeconfig to connect to your new EKS cluster:

bash aws eks --region eu-west-2 update-kubeconfig --name retail-store-eks-cluster

3. Deploy Application with Helm

First, build Helm dependencies, then install the application chart.

bash cd src/app/chart helm dependency build cd ../../.. # Go back to project root helm install retail-store src/app/chart

Accessing the Application

Once the application is deployed, you can access the frontend UI.

Get the External IP/Hostname of the UI service: bash command kubectl get svc ui -n default

Open in Browser: Copy the EXTERNAL-IP and paste it into your web browser.

http://a6759d284b95a4363a26352cfe065e05-872272330.eu-west-2.elb.amazonaws.com/

Developer Access Instructions

The innovatemart-dev-readonly IAM user has read-only access. To enable a developer to access the EKS cluster:

Provide AWS Credentials: Give the developer the AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for the `innovatemart-dev-readonly IAM user.

Developer's Local Setup: On their machine, the developer should:

Set environment variables: bash command export AWS_ACCESS_KEY_ID="<developer_access_key_id>" export AWS_SECRET_ACCESS_KEY="<developer_secret_access_key>"

Updated their kubeconfig (this creates a separate kubeconfig file for them): bash command aws eks --region eu-west-2 update-kubeconfig --name retail-store-eks-cluster --kubeconfig ~/.kube/config-innovatemart-dev

To use this kubeconfig: bash Command export KUBECONFIG=~/.kube/config-innovatemart-dev kubectl get pods -A

They will be able to view resources but will receive "Forbidden" errors if they attempt to modify anything.

Bonus Objectives Implementation: (As detailed in the "Bonus Objectives" section above).
