# CI/CD Pipeline - Quick Reference

## Files Created

### 1. GitHub Actions Workflow
**File**: `.github/workflows/deploy.yml` (550+ lines)

**Jobs**:
- `test` - Run unit, integration, and E2E tests
- `terraform` - Provision AWS infrastructure
- `build-and-push` - Build Docker image and push to ECR
- `deploy-ecs` - Deploy to ECS Fargate
- `health-check` - Verify service health
- `notify` - Pipeline notification and summary

### 2. Docker Configuration
**File**: `Dockerfile`

**Features**:
- Multi-stage build (builder → runtime)
- Alpine Linux base image
- Non-root user (nodejs:1001)
- Health check configuration
- Signal handling with dumb-init

### 3. Terraform Infrastructure

#### Core Files:
- `infrastructure/main.tf` - Provider, CloudWatch logs
- `infrastructure/variables.tf` - Input variables
- `infrastructure/outputs.tf` - Output values
- `infrastructure/terraform.tfvars` - Default values

#### Component Files:
- `infrastructure/networking.tf` - VPC, subnets, routing, security groups
- `infrastructure/ecr.tf` - ECR repository, policies, lifecycle
- `infrastructure/iam.tf` - IAM roles and policies
- `infrastructure/ecs.tf` - ECS cluster, service, ALB, auto-scaling, alarms

#### Configuration:
- `infrastructure/.gitignore` - Git ignore patterns for Terraform

### 4. Documentation
- `DEPLOYMENT_GUIDE.md` - Comprehensive deployment guide

---

## Pipeline Architecture

```
GitHub Push/PR
    ↓
┌─────────────────────────────────────────┐
│  PHASE 1: Testing                       │
│  - Unit tests (backend, frontend)       │
│  - Integration tests                    │
│  - E2E tests (Cypress)                  │
│  - Generate coverage reports            │
└─────────────────────────────────────────┘
    ↓ (success on main/develop)
┌─────────────────────────────────────────┐
│  PHASE 2: Infrastructure (Terraform)    │
│  - Create/configure S3 backend          │
│  - Validate Terraform                   │
│  - Plan infrastructure                  │
│  - Apply changes (main only)            │
└─────────────────────────────────────────┘
    ↓ (success)
┌─────────────────────────────────────────┐
│  PHASE 3: Container Build & Push        │
│  - Multi-stage Docker build             │
│  - Push to ECR                          │
│  - Tag with commit SHA                  │
└─────────────────────────────────────────┘
    ↓ (success)
┌─────────────────────────────────────────┐
│  PHASE 4: ECS Deployment                │
│  - Update task definition               │
│  - Update ECS service                   │
│  - Force new deployment                 │
│  - Wait for stabilization               │
└─────────────────────────────────────────┘
    ↓ (success)
┌─────────────────────────────────────────┐
│  PHASE 5: Health Verification           │
│  - Check service status                 │
│  - Verify running tasks                 │
│  - Test health endpoint                 │
│  - Generate summary                     │
└─────────────────────────────────────────┘
    ↓
✅ Deployment Complete
```

---

## AWS Resources Created

### Networking
- ✓ VPC (10.0.0.0/16)
- ✓ 2 Public subnets (ALB)
- ✓ 2 Private subnets (ECS)
- ✓ Internet Gateway
- ✓ 2 NAT Gateways
- ✓ Route tables (public & private)
- ✓ Security groups (ALB & ECS)

### Container Registry
- ✓ ECR repository (devops-app)
- ✓ Image scanning
- ✓ Lifecycle policies
- ✓ Encryption

### Compute
- ✓ ECS Cluster
- ✓ ECS Service
- ✓ ECS Task Definition
- ✓ Application Load Balancer
- ✓ Target Group
- ✓ Auto Scaling (1-4 tasks)

### Monitoring
- ✓ CloudWatch Log Groups
- ✓ CloudWatch Alarms (CPU, Memory, ALB Health)
- ✓ Container Insights

### Security & Management
- ✓ IAM Task Execution Role
- ✓ IAM Task Role
- ✓ Auto Scaling Role
- ✓ S3 Backend Bucket (with encryption, versioning)

---

## GitHub Secrets Required

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS programmatic access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key |
| `AWS_SESSION_TOKEN` | Optional: temporary credentials |
| `AWS_REGION` | AWS region (e.g., us-east-1) |

---

## Getting Started

### 1. Configure GitHub Secrets
```bash
# Add secrets in: Settings → Secrets and variables → Actions
# Add these 4 secrets:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_SESSION_TOKEN (optional)
# - AWS_REGION
```

### 2. Verify Infrastructure Code
```bash
cd infrastructure
terraform init
terraform validate
terraform plan
```

### 3. Deploy
```bash
# Option A: Push to main branch
git push origin main

# Option B: Create pull request
git push origin develop
# Then create PR on GitHub
```

### 4. Monitor
- Go to Actions tab in GitHub
- Click on the workflow run
- Monitor job progress and logs

---

## Key Features

### ✅ Security
- Non-root Docker user
- Private subnets for application
- S3 encryption and versioning
- IAM least privilege
- Health checks

### ✅ Scalability
- Auto-scaling (CPU & memory)
- Multi-AZ deployment
- Load balancer
- Capacity providers (FARGATE + FARGATE_SPOT)

### ✅ Reliability
- Deployment circuit breaker
- Health checks (ALB + container)
- CloudWatch monitoring
- Automatic rollback

### ✅ Testing
- Multi-version Node.js testing
- Unit, integration, E2E tests
- Test artifact storage
- Coverage reports

### ✅ Best Practices
- Infrastructure as Code
- Immutable infrastructure
- Automated deployments
- Comprehensive logging
- Health verification

---

## Configuration Customization

### Update Task Resources
Edit `infrastructure/terraform.tfvars`:
```hcl
ecs_task_cpu    = 512      # Increase for more CPU
ecs_task_memory = 1024     # Increase for more memory
```

### Change Auto-scaling Limits
```hcl
auto_scaling_min_capacity = 1    # Minimum tasks
auto_scaling_max_capacity = 4    # Maximum tasks
cpu_target_tracking_value = 70   # Scale at 70% CPU
```

### Adjust Health Check Sensitivity
```hcl
health_check_interval             = 30   # Check every 30s
health_check_timeout              = 5    # 5s timeout
health_check_healthy_threshold    = 2    # 2 healthy checks
health_check_unhealthy_threshold  = 3    # 3 failures to mark unhealthy
```

---

## Monitoring Dashboard

Access your deployment:
1. **Application URL**: Get from Terraform outputs
   ```bash
   cd infrastructure
   terraform output application_url
   ```

2. **CloudWatch Logs**:
   - ECS logs: `/ecs/devops-app-production`
   - ALB logs: `/alb/devops-app-production`

3. **AWS Console**:
   - ECS → Clusters → devops-app-cluster
   - EC2 → Load Balancers → devops-app-alb
   - ECR → Repositories → devops-app

---

## Cost Optimization

1. **Use FARGATE_SPOT** for non-critical workloads:
   - Up to 70% cost savings
   - Edit `infrastructure/ecs.tf` capacity provider weights

2. **Adjust auto-scaling** based on load:
   - Reduce `auto_scaling_max_capacity` if over-provisioned
   - Increase thresholds if scaling too aggressively

3. **Enable image lifecycle policies**:
   - Automatically delete old images
   - Configured in `infrastructure/ecr.tf`

---

## Troubleshooting

### Workflow Fails at Testing
- Check test output in GitHub Actions logs
- Verify `npm test` passes locally

### Terraform Plan Fails
- Verify AWS credentials are correct
- Check IAM permissions
- Review Terraform errors in logs

### Docker Build Fails
- Review Dockerfile syntax
- Check that all files referenced exist
- Verify Docker build context

### ECS Deployment Hangs
- Check CloudWatch logs for application errors
- Verify health check path is correct
- Ensure security groups allow traffic

---

## Production Checklist

- [ ] GitHub secrets configured
- [ ] Terraform plan reviewed and approved
- [ ] S3 backend bucket created
- [ ] Docker image builds successfully
- [ ] ECS tasks pass health checks
- [ ] ALB reports healthy targets
- [ ] CloudWatch alarms configured
- [ ] Monitoring dashboard created
- [ ] Backup strategy documented
- [ ] Incident response plan ready

