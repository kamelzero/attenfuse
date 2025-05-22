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

To allow EC2 instances to clone the private repository, you need to create a GitHub Personal Access Token (PAT) and configure it properly:

1. Create a GitHub PAT:
   - Go to GitHub.com → Settings → Developer settings → Personal access tokens
   - Generate new token (classic)
   - Set appropriate permissions (at minimum "repo" access)
   - Copy the token immediately after generation

2. Add the token to `terraform/variables.tf`:
```hcl
variable "github_token" {
  description = "GitHub Personal Access Token for repository access"
  type        = string
  sensitive   = true
}
```

3. Create `terraform/terraform.tfvars` (make sure it's in .gitignore):
```hcl
github_token = "your_github_pat_here"
```

4. Update your `main.tf` to pass the token to cloud-init:
```hcl
user_data = templatefile("${path.module}/cloud-init.sh", {
  github_token = var.github_token
  // ... other variables ...
})
```

**Important**: Ensure `terraform.tfvars` is in your `.gitignore` to prevent accidentally committing your token.

## Creating a Base AMI

To speed up spot instance startup times, we use a custom AMI with Docker images pre-pulled. To create/update this AMI:

1. Ensure your base AMI ID in `terraform.tfvars` points to a basic Ubuntu AMI
2. Run the AMI creation script:
   ```bash
   chmod +x create_base_ami.sh
   ./create_base_ami.sh
   ```

3. The script will:
   - Launch a temporary instance
   - Install dependencies and pull Docker images
   - Create an AMI
   - Clean up the temporary instance
   - Output the new AMI ID

4. Update `terraform.tfvars` with the new AMI ID

This AMI will contain:
- All system dependencies
- Docker and Docker Compose
- Pre-pulled Docker images

Benefits:
- Faster spot instance startup
- Reduced risk of spot interruption during setup
- Lower data transfer costs
