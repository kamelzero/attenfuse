# Terraform Usage Guide for CARLA RL Project

This guide explains how to deploy and manage AWS infrastructure using Terraform and Docker for your CARLA + Reinforcement Learning project.

---

## ✅ Prerequisites

Install required tools:
```bash
sudo apt install terraform awscli
```

Configure AWS credentials:
```bash
aws configure
```

---

## 📁 Complete Directory Structure

```
carla-project/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   ├── setup_backend.sh
│   ├── cloud-init.sh
│   ├── docker-compose.yml
│   ├── Dockerfile.base
│   └── requirements.txt
├── launch_training.sh
└── src/
    └── train.py
```

---

## 🔒 Setting Up Remote State Storage

Before initializing Terraform, you need to set up remote state storage. This ensures your Terraform state is stored securely in S3 and can be shared across team members.

### Step 1: Configure Backend Infrastructure
```bash
cd terraform/
./setup_backend.sh
```

This script creates:
- An S3 bucket for storing Terraform state
- A DynamoDB table for state locking
- Required IAM permissions

The `backend.tf` file is configured to use these resources automatically.

---

## ✏️ Required Edits Before Use

### `main.tf`
- Update the AMI ID (specific to your AWS region):
```hcl
ami = "ami-0284440fc8de0d5e8"
```

- Update SSH key path to match your local key:
```hcl
public_key = file("~/.ssh/id_ed25519.pub")
```

- The S3 bucket for logs will be automatically created by Terraform.

### `docker-compose.yml`
- The bucket name will be automatically configured via cloud-init.sh using Terraform outputs:
```yaml
environment:
  - BUCKET_NAME=${bucket_name}  # This will be replaced with the actual bucket name
```

- Replace the Docker image name if you're using a prebuilt one:
```yaml
image: your-dockerhub-username/your-image:latest
```

Or build from `Dockerfile.base` using:
```yaml
build:
  context: .
  dockerfile: Dockerfile.base
```

### Infrastructure Components Created

Terraform will create:
- EC2 instance for training
- S3 bucket for storing logs and models
- Required IAM roles and permissions
- Security groups
- SSH key pair

---

## 🛠️ Deploying Infrastructure

### Step 1: Initialize Terraform with Backend
```bash
cd terraform/
terraform init
# Terraform will automatically use the S3 backend configured in backend.tf
```

### Step 2: Preview Deployment
```bash
terraform plan
```

### Step 3: Launch Infrastructure
```bash
terraform apply
# Confirm with 'yes' when prompted
```

---

## 🚀 Running Your Code on EC2

### Automatically via script:
```bash
./launch_training.sh
```

This script:
- Looks up the EC2 instance by tag
- SSHs in
- Runs `docker compose up -d`

### Or manually:
```bash
ssh -i ~/.ssh/id_ed25519 ubuntu@<public-ip>
cd ~/carla-project/
docker compose build
docker compose up -d
```

---

## 🧹 Cleaning Up (Teardown)

To avoid charges:
```bash
terraform destroy
# Confirm with 'yes'
```

---

## ✅ Summary of Commands

| Task              | Command                      |
|-------------------|------------------------------|
| Initialize        | `terraform init`             |
| Plan              | `terraform plan`             |
| Deploy            | `terraform apply`            |
| Start container   | `./launch_training.sh`       |
| Teardown          | `terraform destroy`          |

---

## 📌 Tips

- Use VSCode Remote SSH to edit code in `src/`
- The container will mount `src/` as `/app` for live editing
- Logs and models are automatically synced to the created S3 bucket
- The S3 bucket name can be found in Terraform outputs after deployment
- Terraform state is stored remotely in S3, allowing team collaboration
- State locking via DynamoDB prevents concurrent modifications
