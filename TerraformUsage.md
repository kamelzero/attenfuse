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
attenfuse/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── setup_backend.sh
├── docker/
│   ├── Dockerfile.base
│   └── requirements.txt
├── docker-compose.yml
├── cloud-init.sh
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
ami = "ami-0fcdcdcc9cf0407ae"
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
cd ~/attenfuse/
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

## GitHub Token Setup

To allow EC2 instances to clone the private repository, you need to create a GitHub Personal Access Token (PAT) with the correct permissions:

1. Go to GitHub.com and sign in
2. Click your profile picture → Settings
3. Scroll down to "Developer settings" (bottom of left sidebar)
4. Click "Personal access tokens" → "Tokens (classic)"
5. Click "Generate new token" → "Generate new token (classic)"
6. Configure the token:
   - Note: "CARLA EC2 Clone" (or similar descriptive name)
   - Expiration: Choose as needed (e.g., 90 days)
   - Permissions:
     - Select "repo" (this includes Contents: Read access needed for cloning)
   - Click "Generate token"
   - **Important**: Copy the token immediately - it won't be shown again

7. Add the token to `terraform/terraform.tfvars`:
   ```hcl
   github_token = "ghp_your_new_token_here"
   ```

8. Ensure `terraform.tfvars` is in `.gitignore` to prevent committing the token

Note: The minimum required permission is "Contents: Read" under Repository permissions, but selecting the "repo" scope is simpler and ensures all necessary read access.
