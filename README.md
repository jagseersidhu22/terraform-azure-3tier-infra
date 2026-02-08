Terraform code to provision a production-ready 3-tier application infrastructure on Azure with Dev, Pre-Prod, and Prod environments, integrated with CI/CD pipelines and DevSecOps practices.

🏗 Architecture Overview

Modular 3-tier application infrastructure:

Web, App, DB tiers on Azure VMs

VNet with subnets (Web / App / DB)

Network Security Groups (NSGs)

Azure Key Vault for secrets

Remote Terraform state in Azure Blob Storage

Each environment is isolated for safe, repeatable deployments.

🌍 Environments
Environment	State File	Purpose
Dev	dev.tfstate	Development & testing
Pre-Prod	preprod.tfstate	Staging / validation
Prod	prod.tfstate	Production
🔐 State Management

Remote backend with Azure Storage Account

Separate state files per environment

Enables collaboration, version control, and controlled changes

🔒 DevSecOps Steps (Short)

Branching Strategy:

Trunk-based development

Feature branches → Dev & Pre-Prod pipelines

Main branch → Prod pipeline (manual approval)

Terraform Quality Checks:

TFLint → Terraform linting

TFsec → Security scanning

Infracost → Cost estimation

CI/CD Pipelines:

Automated build & plan for each environment

Artifacts published to Azure storage / pipeline artifacts

Prod deployment gated with manual validation

Secrets & Config Management:

Sensitive info in Azure Key Vault

Secure pipeline variables & secrets

Environment Isolation:

Separate Terraform state files per environment

Reduces risk & ensures controlled deployments

📦 Key Features

Production-ready 3-tier architecture

Modular Terraform design

Secure networking & secrets management

Remote state management & environment isolation

Integrated IaC quality checks, security, and cost awareness

Supports trunk-based DevOps workflow

🧰 Tools & Technologies

Terraform

Microsoft Azure (VNet, VMs, Key Vault, Blob Storage)

Azure DevOps Pipelines & YAML

TFLint, TFsec, Infracost

Git & GitHub
