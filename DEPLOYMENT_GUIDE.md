# CI/CD Pipeline & Infrastructure as Code Documentation

This document provides comprehensive guidance on the GitHub Actions CI/CD pipeline and Terraform infrastructure setup for cloud-native application deployment on AWS.

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [GitHub Secrets Configuration](#github-secrets-configuration)
5. [Workflow Phases](#workflow-phases)
6. [Infrastructure Setup](#infrastructure-setup)
7. [Deployment Instructions](#deployment-instructions)
8. [Monitoring & Maintenance](#monitoring--maintenance)
9. [Troubleshooting](#troubleshooting)
10. [Security Best Practices](#security-best-practices)

---

## Overview

This CI/CD pipeline automates:
- **Testing**: Unit tests, integration tests, and E2E tests
- **Infrastructure Provisioning**: AWS resources via Terraform
- **Container Builds**: Multi-stage Docker builds pushed to ECR
- **Deployment**: Automated deployment to ECS Fargate
- **Health Verification**: Post-deployment service health checks

### Trigger Events
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches

---

## Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────┐
│                   AWS Account                       │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │           VPC (10.0.0.0/16)                  │  │
│  │                                              │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  Public Subnets (ALB)                │  │  │
│  │  │  - 10.0.10.0/24 (us-east-1a)        │  │  │
│  │  │  - 10.0.11.0/24 (us-east-1b)        │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  │                    ↓                        │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  ALB (Application Load Balancer)     │  │  │
│  │  │  - Port 80 (HTTP)                    │  │  │
│  │  │  - Health checks every 30s           │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  │                    ↓                        │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  Private Subnets (ECS Tasks)        │  │  │
│  │  │  - 10.0.1.0/24 (us-east-1a)         │  │  │
│  │  │  - 10.0.2.0/24 (us-east-1b)         │  │  │
│  │  │                                      │  │  │
│  │  │  ┌──────────────────────────────┐   │  │  │
│  │  │  │  ECS Fargate Cluster         │   │  │  │
│  │  │  │  - Task Definition           │   │  │  │
│  │  │  │  - Service (2 tasks min)     │   │  │  │
│  │  │  │  - Auto-scaling (1-4 tasks)  │   │  │  │
│  │  │  └──────────────────────────────┘   │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  │                    ↓                        │  │
│  │  ┌──────────────────────────────────────┐  │  │
│  │  │  NAT Gateways (Private outbound)    │  │  │
│  │  └──────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  ECR Repository (devops-app)                 │  │
│  │  - Image scanning enabled                    │  │
│  │  - Lifecycle policies                        │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  S3 Bucket (Terraform State)                 │  │
│  │  - Versioning enabled                        │  │
│  │  - Encryption enabled                        │  │
│  │  - Public access blocked                     │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │  CloudWatch (Logs & Monitoring)              │  │
│  │  - ECS logs: /ecs/devops-app-production      │  │
│  │  - ALB logs: /alb/devops-app-production      │  │
│  │  - Alarms for CPU, memory, unhealthy hosts  │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Tools
- AWS Account with appropriate permissions
- Git and GitHub repository access
- Docker (for local testing)
- Terraform >= 1.5.0
- AWS CLI v2

### AWS Permissions
Ensure the IAM user/role has permissions for:
- EC2 (VPC, Subnets, Security Groups, NAT)
- ECS (Clusters, Services, Task Definitions)
- ECR (Repository creation and management)
- CloudWatch (Logs and Alarms)
- S3 (State management)
- IAM (Role creation and policy attachment)
- Application Auto Scaling

### GitHub Requirements
- Repository with GitHub Actions enabled
- Write access to set repository secrets

---

## GitHub Secrets Configuration

### Required Secrets

1. **AWS_ACCESS_KEY_ID**
   - AWS Access Key ID for programmatic access
   - Create in IAM → Security credentials

2. **AWS_SECRET_ACCESS_KEY**
   - AWS Secret Access Key
   - Store securely; cannot be retrieved later

3. **AWS_SESSION_TOKEN** (Optional)
   - Required if using temporary credentials
   - Leave blank for permanent credentials

4. **AWS_REGION**
   - AWS region for deployment (e.g., `us-east-1`)

### Setting Secrets in GitHub

1. Go to Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add each secret with the name and value
4. Save

**Security Note**: Secrets are encrypted and never logged. Rotate credentials regularly.

---

## Workflow Phases

### Phase 1: Testing

**Purpose**: Validate code quality before deployment

**Steps**:
1. Checkout source code
2. Setup Node.js environments (18.x, 20.x)
3. Install backend dependencies
4. Run backend unit tests with coverage
5. Install frontend dependencies
6. Run frontend unit tests with coverage
7. Run integration tests (backend API)
8. Run Cypress E2E tests
9. Upload coverage reports and videos as artifacts

**Artifacts Generated**:
- `backend-coverage-*`: Backend code coverage
- `frontend-coverage-*`: Frontend code coverage
- `cypress-results-*`: E2E test videos

**Retention**: 30 days

---

### Phase 2: Infrastructure Provisioning (Terraform)

**Purpose**: Create and manage AWS infrastructure

**Steps**:
1. Configure AWS credentials
2. Create/configure S3 backend bucket
3. Enable bucket versioning
4. Enable server-side encryption (AES256)
5. Block all public access
6. Initialize Terraform
7. Validate Terraform configuration
8. Check Terraform format
9. Generate Terraform plan
10. Apply Terraform changes (main branch only)
11. Export Terraform outputs

**AWS Resources Created**:
- **VPC** with public and private subnets
- **Internet Gateway** for public access
- **NAT Gateways** for private subnet egress
- **Route Tables** for traffic routing
- **Security Groups** for ALB and ECS
- **ECR Repository** for Docker images
- **ECS Cluster** with Fargate capacity providers
- **ECS Service** with task auto-scaling
- **Application Load Balancer** with health checks
- **IAM Roles** for ECS task execution and application
- **CloudWatch Log Groups** for centralized logging
- **CloudWatch Alarms** for monitoring

---

### Phase 3: Container Build and ECS Deployment

**Purpose**: Build Docker image and deploy to ECS

**Build Process**:
1. Checkout code
2. Configure AWS credentials
3. Login to ECR
4. Setup Docker Buildx (for multi-stage builds)
5. Build Docker image with:
   - Multi-stage build (builder → runtime)
   - Non-root user (nodejs:1001)
   - Security best practices
   - Health checks
6. Push image to ECR with tags:
   - `latest`: Latest build
   - `{commit-sha}`: Specific commit

**Push Target**:
- Amazon ECR: `{account-id}.dkr.ecr.{region}.amazonaws.com/devops-app`

**Docker Image Features**:
- Alpine Linux base (minimal size)
- Non-root user (security)
- Health check configuration
- Proper signal handling (dumb-init)
- Environment-based configuration

**Deployment**:
1. Download current ECS task definition
2. Update task definition with new image
3. Register new task definition revision
4. Update ECS service
5. Force new deployment
6. Wait for service stabilization

---

### Phase 4: Health Verification

**Purpose**: Ensure service is healthy and operational

**Checks**:
1. Verify ECS service status
2. Check running task count
3. Verify task health status
4. Test application health endpoint (optional)
5. Generate deployment summary

**Verification Points**:
- Service status: ACTIVE
- Running count = Desired count
- All tasks passing health checks
- ALB reports healthy targets

---

## Infrastructure Setup

### Initial Terraform Configuration

1. **Navigate to infrastructure directory**:
   ```bash
   cd infrastructure
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Review variables** in `terraform.tfvars`:
   ```bash
   cat terraform.tfvars
   ```

4. **Customize if needed**:
   ```bash
   # Edit terraform.tfvars for your environment
   vim terraform.tfvars
   ```

5. **Validate configuration**:
   ```bash
   terraform validate
   ```

6. **Plan deployment**:
   ```bash
   terraform plan -out=tfplan
   ```

7. **Apply infrastructure** (manual for first-time):
   ```bash
   terraform apply tfplan
   ```

### S3 Backend for State

The pipeline automatically manages the S3 backend:
1. Bucket name: `devops-terraform-state-{github_owner}-{region}`
2. Versioning enabled
3. Encryption enabled (AES256)
4. Public access blocked

**Manual backend configuration** (optional):
```bash
terraform init \
  -backend-config="bucket=devops-terraform-state-us-east-1" \
  -backend-config="key=terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="encrypt=true"
```

---

## Deployment Instructions

### Automatic Deployment (via GitHub Actions)

1. **Trigger by pushing to main**:
   ```bash
   git add .
   git commit -m "Deploy new version"
   git push origin main
   ```

2. **Monitor workflow**:
   - Go to Actions tab in GitHub
   - Click on the workflow run
   - Review each job's progress

### Manual Deployment

1. **Run tests locally**:
   ```bash
   cd backend && npm test
   cd ../frontend && npm test
   ```

2. **Build Docker image**:
   ```bash
   docker build -t devops-app:latest .
   ```

3. **Test Docker image**:
   ```bash
   docker run -p 3000:3000 devops-app:latest
   curl http://localhost:3000/health
   ```

4. **Apply infrastructure changes**:
   ```bash
   cd infrastructure
   terraform plan
   terraform apply
   ```

5. **Push image to ECR**:
   ```bash
   aws ecr get-login-password --region us-east-1 | \
     docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-east-1.amazonaws.com
   
   docker tag devops-app:latest {account-id}.dkr.ecr.us-east-1.amazonaws.com/devops-app:latest
   docker push {account-id}.dkr.ecr.us-east-1.amazonaws.com/devops-app:latest
   ```

6. **Update ECS service**:
   ```bash
   aws ecs update-service \
     --cluster devops-app-cluster \
     --service devops-app-service \
     --force-new-deployment \
     --region us-east-1
   ```

---

## Monitoring & Maintenance

### CloudWatch Dashboards

Create a custom dashboard to monitor:
- ECS service metrics (CPU, memory, task count)
- ALB metrics (request count, target health)
- Application logs
- Alarm history

### CloudWatch Alarms

**Active Alarms**:
1. **ECS CPU High** (> 80%)
2. **ECS Memory High** (> 85%)
3. **ALB Unhealthy Hosts** (≥ 1)

### Log Insights Queries

**ECS Application Logs**:
```
fields @timestamp, @message, @logStream
| filter @logStream like /ecs/
| stats count() by bin(5m)
```

**ALB Access Logs**:
```
fields @timestamp, elb_status_code, request_count
| stats sum(request_count) by bin(5m)
```

**Error Analysis**:
```
fields @timestamp, @message
| filter @message like /ERROR|error|Exception/
| stats count() as error_count by @logStream
```

### Scaling Policies

**Metrics Used**:
- **CPU Utilization**: Target 70%
- **Memory Utilization**: Target 80%

**Scaling Behavior**:
- Scale up: 1 minute from threshold
- Scale down: 5 minutes from threshold
- Min tasks: 1
- Max tasks: 4

### Backup & Disaster Recovery

**Terraform State Backup**:
```bash
# S3 versioning is enabled by default
# Retrieve previous state versions:
aws s3api list-object-versions \
  --bucket devops-terraform-state-{region} \
  --prefix terraform.tfstate
```

**ECR Image Backup**:
```bash
# Pull and store image locally
docker pull {account-id}.dkr.ecr.us-east-1.amazonaws.com/devops-app:latest
docker tag devops-app:latest devops-app:backup-$(date +%Y%m%d)
```

---

## Troubleshooting

### Common Issues

#### 1. GitHub Actions Secrets Not Found
**Error**: `"secrets.AWS_ACCESS_KEY_ID is not set"`

**Solution**:
- Verify secrets in Settings → Secrets
- Check secret names match exactly
- Wait 1-2 minutes after adding secrets

#### 2. Terraform Backend Initialization Fails
**Error**: `Error: resource does not exist`

**Solution**:
```bash
# Reset Terraform
rm -rf infrastructure/.terraform
cd infrastructure
terraform init -reconfigure
```

#### 3. ECR Login Fails
**Error**: `Error: no credentials provided`

**Solution**:
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-east-1.amazonaws.com
```

#### 4. ECS Deployment Hangs
**Error**: `Waiting for ECS service to stabilize...`

**Solution**:
```bash
# Check service status
aws ecs describe-services \
  --cluster devops-app-cluster \
  --services devops-app-service \
  --region us-east-1

# View task events
aws ecs describe-tasks \
  --cluster devops-app-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster devops-app-cluster \
    --query 'taskArns[0]' \
    --output text) \
  --region us-east-1
```

#### 5. Health Check Failures
**Error**: `Target has failed at least the Unhealthy Threshold...`

**Solution**:
```bash
# Check application logs
aws logs tail /ecs/devops-app-production --follow

# Test health endpoint locally
curl http://{ALB_DNS}/health

# Verify security group allows traffic
aws ec2 describe-security-groups \
  --group-ids {ecs_security_group_id}
```

#### 6. Container OOM (Out of Memory)
**Error**: `Container exited with code 137`

**Solution**:
- Increase task memory: Edit `infrastructure/terraform.tfvars`
- Change `ecs_task_memory` from 1024 to 2048
- Reapply: `terraform apply`

---

## Security Best Practices

### GitHub Actions Security

1. **Use secrets for sensitive data**:
   ```yaml
   - name: Configure AWS credentials
     uses: aws-actions/configure-aws-credentials@v2
     with:
       aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
       aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
   ```

2. **Limit workflow permissions**:
   ```yaml
   permissions:
     contents: read
     id-token: write
   ```

3. **Use OIDC for AWS authentication** (recommended):
   - Eliminates need for long-lived credentials
   - Configure trust relationship between GitHub and AWS

### Docker Security

1. **Non-root user**:
   ```dockerfile
   RUN addgroup -g 1001 -S nodejs
   RUN adduser -S nodejs -u 1001
   USER nodejs
   ```

2. **Multi-stage builds**:
   - Reduces image size
   - Excludes build tools from runtime
   - Minimizes attack surface

3. **Image scanning**:
   - ECR scans for vulnerabilities on push
   - Implement remediation policies

### AWS Infrastructure Security

1. **VPC Isolation**:
   - Private subnets for application
   - Public subnets for ALB only
   - NAT for outbound traffic

2. **Security Groups**:
   - ALB: Allow 80/443 from internet
   - ECS: Allow only from ALB
   - Minimal required permissions

3. **IAM Least Privilege**:
   - Task execution role: Pull images, write logs
   - Task role: Application-specific permissions
   - Service role: ALB traffic management

4. **Encryption**:
   - S3 state bucket: AES256 encryption
   - ECR images: Encrypted by default
   - CloudWatch logs: KMS encryption (optional)

5. **Monitoring & Logging**:
   - CloudWatch Container Insights
   - ALB access logs
   - API call logging (CloudTrail)

### Secrets Management

1. **Rotate credentials** every 90 days:
   ```bash
   # Create new IAM access keys
   aws iam create-access-key --user-name github-actions-user
   
   # Update GitHub secrets
   # Delete old key:
   aws iam delete-access-key --user-name github-actions-user \
     --access-key-id AKIAIOSFODNN7EXAMPLE
   ```

2. **Use Secrets Manager** for application secrets:
   ```bash
   aws secretsmanager create-secret \
     --name devops-app/database/password \
     --secret-string 'your-password'
   ```

---

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

---

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions
2. Review CloudWatch logs
3. Verify AWS resource status in console
4. Consult Terraform state: `terraform state list`

