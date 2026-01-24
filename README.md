# terraform-azure-3tier-infra
Terraform code to provision a production-ready 3-tier application infrastructure on Azure with Dev, Pre-Prod, and Prod environments.
# 3-Tier Application Infrastructure on Azure (Terraform)

This repository contains Terraform code to provision a **production-ready 3-tier application infrastructure** on **Microsoft Azure** using **Infrastructure as Code (IaC)** principles.

The setup supports **Dev, Pre-Prod, and Prod** environments, each created once and managed independently with separate Terraform state files.

---

## 🏗 Architecture Overview

Each environment provisions the following components:

- Resource Group (RG)
- Virtual Network (VNet)
- Subnets (Web / App / DB)
- Network Security Groups (NSGs)
- Network Interfaces (NICs)
- Virtual Machines (Web Tier & App Tier)
- Database Tier (VM-based)
- Azure Key Vault (Secrets Management)
- Remote Terraform State stored in Azure Blob Storage

---

## 🌍 Environments

| Environment | State File | Purpose |
|------------|-----------|---------|
| Dev        | dev.tfstate        | Development & testing |
| Pre-Prod  | preprod.tfstate    | Staging / validation |
| Prod      | prod.tfstate       | Production |

Each environment is **isolated** and managed independently to avoid cross-impact.

---

## 🔐 State Management

- Terraform remote backend configured using **Azure Storage Account**
- Separate state files for:
  - Dev
  - Pre-Prod
  - Prod
- Enables safe collaboration and controlled infrastructure changes

---

## 📦 Key Features

✔ Clean environment isolation  
✔ Secure networking using NSGs  
✔ Secrets stored securely in Azure Key Vault  
✔ Scalable and modular Terraform design  
✔ Production-ready 3-tier architecture  
✔ Supports controlled and repeatable deployments  

---

## 🧰 Tools & Technologies Used

- Terraform
- Microsoft Azure
- Azure Virtual Network
- Azure Virtual Machines
- Azure Key Vault
- Azure Blob Storage (Remote Backend)
- Git & GitHub

---

## 🚀 How to Deploy

### 1️⃣ Authenticate to Azure
```bash
az login
