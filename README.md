# DevOps Project - Cloud-Native AWS Deployment

A complete, production-ready CI/CD pipeline and Infrastructure as Code (IaC) solution for deploying cloud-native applications on AWS using GitHub Actions, Terraform, Docker, and ECS Fargate.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [CI/CD Pipeline](#cicd-pipeline)
- [Infrastructure Setup](#infrastructure-setup)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

This project provides a complete DevOps solution for deploying a cloud-native application on AWS. It includes:

- **Automated Testing** - Unit, integration, and E2E tests
- **Infrastructure as Code** - Terraform for AWS resource provisioning
- **Container Orchestration** - Docker multi-stage builds and ECR registry
- **Serverless Compute** - ECS Fargate with auto-scaling
- **Load Balancing** - Application Load Balancer with health checks
- **Monitoring** - CloudWatch logs, metrics, and alarms
- **CI/CD Pipeline** - GitHub Actions for automated deployments

### Key Features

✅ Fully automated deployment pipeline  
✅ Multi-stage Docker builds with security hardening  
✅ Infrastructure provisioning with Terraform  
✅ Auto-scaling based on CPU and memory  
✅ Multi-AZ high availability  
✅ Comprehensive monitoring and alerting  
✅ Security best practices implemented  
✅ Environment-specific configurations  

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   GitHub Repository                         │
│         (Source Code + CI/CD Workflow + IaC)               │
└──────────────────────────┬──────────────────────────────────┘
                           │
                    (git push / PR)
                           │
                           ▼
            ┌──────────────────────────────┐
            │   GitHub Actions Workflow    │
            │                              │
            │  1. Test (Unit, Integ, E2E) │
            │  2. Terraform (IaC)         │
            │  3. Build & Push (Docker)   │
            │  4. Deploy (ECS)            │
            │  5. Health Check (Verify)   │
            │  6. Notify (Summary)        │
            └──────────────────┬───────────┘
                               │
                               ▼
                     ┌──────────────────┐
                     │   AWS Account    │
                     │                  │
        ┌────────────┼──────────────────┼────────────┐
        │            │                  │            │
        ▼            ▼                  ▼            ▼
    ┌────────┐  ┌────────┐          ┌────────┐  ┌────────┐
    │  VPC   │  │  ECR   │          │  ECS   │  │  ALB   │
    │(Network)│ │(Images)│          │(Fargate)│ │(Access)│
    └────────┘  └────────┘          └────────┘  └────────┘
        │            │                  │            │
        └────────────┼──────────────────┼────────────┘
                     │
                     ▼
          Application Live ✅
```

---

## 💻 Technology Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Container Runtime** | Docker | Latest |
| **Base Image** | Alpine Linux | 3.x |
| **Backend** | Node.js | 20.x |
| **Frontend** | React | Latest |
| **IaC** | Terraform | 1.5+ |
| **CI/CD** | GitHub Actions | Latest |
| **Container Registry** | Amazon ECR | - |
| **Orchestration** | Amazon ECS Fargate | - |
| **Load Balancer** | Application Load Balancer | - |
| **Networking** | AWS VPC | - |
| **Monitoring** | CloudWatch | - |
| **Logging** | CloudWatch Logs | - |
| **Testing** | Jest, Cypress | Latest |

---

## 🚀 Quick Start

### Prerequisites

- AWS Account with IAM permissions
- GitHub repository with Actions enabled
- Git and Docker installed locally
- Terraform >= 1.5.0
- Node.js 18+ and npm

### 1. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
AWS_ACCESS_KEY_ID          # AWS programmatic access key
AWS_SECRET_ACCESS_KEY      # AWS secret key
AWS_SESSION_TOKEN          # Optional: temporary credentials
AWS_REGION                 # e.g., us-east-1
```

### 2. Update Application Health Endpoint

Add a `/health` endpoint to your backend (required by health checks):

```javascript
// backend/server.js
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

See [HEALTH_CHECK_GUIDE.md](HEALTH_CHECK_GUIDE.md) for complete implementation.

### 3. Deploy

```bash
# Commit and push to main branch
git add .
git commit -m "Initial commit with CI/CD pipeline"
git push origin main

# Monitor deployment in GitHub Actions
# Actions tab → Latest run → View logs
```

### 4. Access Application

After deployment completes:

```bash
# Get ALB DNS name
cd infrastructure
terraform output application_url

# Test health endpoint
curl http://{ALB_DNS}/health

# Access application
open http://{ALB_DNS}
```

---

## 📁 Project Structure

```
devops-project/
├── .github/
│   └── workflows/
│       └── deploy.yml                    # CI/CD Pipeline (550+ lines)
│
├── infrastructure/                       # Infrastructure as Code
│   ├── main.tf                          # Provider & CloudWatch
│   ├── variables.tf                     # Input variables
│   ├── outputs.tf                       # Output values
│   ├── terraform.tfvars                 # Configuration
│   ├── networking.tf                    # VPC & Networking
│   ├── ecr.tf                           # Container Registry
│   ├── iam.tf                           # Security & Permissions
│   ├── ecs.tf                           # ECS & ALB
│   └── .gitignore
│
├── backend/                             # Backend Application
│   ├── server.js                        # Express server
│   ├── package.json
│   ├── routes/
│   └── tests/
│
├── frontend/                            # Frontend Application
│   ├── public/
│   ├── src/
│   └── package.json
│
├── cypress/                             # E2E Tests
│   ├── e2e/
│   ├── fixtures/
│   └── support/
│
├── Dockerfile                           # Multi-stage Docker build
├── DEPLOYMENT_GUIDE.md                  # Comprehensive deployment guide
├── CICD_QUICK_REFERENCE.md             # Quick reference & checklist
├── ENVIRONMENT_CONFIG.md                # Environment configurations
├── HEALTH_CHECK_GUIDE.md               # Health check implementation
├── IMPLEMENTATION_SUMMARY.md            # Project summary
├── README.md                            # This file
└── package.json
```

---

## 🔄 CI/CD Pipeline

The GitHub Actions workflow automates the entire deployment process:

### Phase 1: Testing
- Unit tests (backend & frontend)
- Integration tests
- E2E tests with Cypress
- Coverage reports
- **Artifacts**: Test reports and coverage data

### Phase 2: Infrastructure Provisioning (Terraform)
- Initialize Terraform with S3 backend
- Validate configuration
- Generate plan
- Apply infrastructure changes (main branch only)
- **Resources Created**: VPC, ECS, ECR, ALB, IAM roles, CloudWatch, etc.

### Phase 3: Build & Push Docker Image
- Multi-stage Docker build
- Alpine Linux base (minimal size)
- Non-root user for security
- Push to Amazon ECR
- Tag with commit SHA and "latest"

### Phase 4: Deploy to ECS Fargate
- Update ECS task definition
- Update ECS service
- Force new deployment
- Wait for service stabilization

### Phase 5: Health Verification
- Check service status
- Verify running tasks
- Test health endpoint
- Generate deployment summary

### Phase 6: Notification
- Pipeline status summary
- Success/failure reporting

**Triggers**: Push to `main` or `develop` | Pull requests to `main` or `develop`

---

## 🏛️ Infrastructure Setup

### AWS Resources Created (35+)

#### Networking
- VPC (10.0.0.0/16)
- 2 Public Subnets (ALB)
- 2 Private Subnets (Application)
- Internet Gateway
- 2 NAT Gateways
- Route Tables
- Security Groups

#### Compute
- ECS Cluster (Fargate)
- Task Definition
- ECS Service (auto-scaling 1-4 tasks)
- Application Load Balancer
- Target Group

#### Container Registry
- ECR Repository
- Image scanning
- Lifecycle policies
- Encryption

#### Monitoring
- CloudWatch Log Groups (ECS + ALB)
- CloudWatch Alarms (CPU, Memory, Health)
- Container Insights

#### Security & Identity
- IAM Task Execution Role
- IAM Task Role
- IAM Service Role
- IAM Auto Scaling Role
- S3 Backend Bucket (encrypted, versioned)

### Scaling Configuration

**Auto-scaling Policies**:
- Min tasks: 1
- Max tasks: 4
- CPU target: 70%
- Memory target: 80%
- Scale-up: 1 minute
- Scale-down: 5 minutes

### Security Features

✅ VPC with private subnets  
✅ Non-root Docker user  
✅ S3 encryption and versioning  
✅ IAM least privilege  
✅ Security group isolation  
✅ Health checks  
✅ Container image scanning  

---

## 📤 Deployment

### Automatic Deployment

```bash
# Push to main branch
git push origin main

# Monitor in GitHub Actions
# Actions tab → deploy workflow → View logs
```

### Manual Infrastructure Changes

```bash
# Navigate to infrastructure directory
cd infrastructure

# Validate changes
terraform validate
terraform fmt

# Review changes
terraform plan

# Apply changes (requires AWS credentials)
terraform apply
```

### Manual Docker Build & Test

```bash
# Build Docker image
docker build -t devops-app:latest .

# Test locally
docker run -p 3000:3000 devops-app:latest

# Health check
curl http://localhost:3000/health

# Push to ECR (if needed)
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin {account-id}.dkr.ecr.us-east-1.amazonaws.com

docker tag devops-app:latest {account-id}.dkr.ecr.us-east-1.amazonaws.com/devops-app:latest
docker push {account-id}.dkr.ecr.us-east-1.amazonaws.com/devops-app:latest
```

---

## 📊 Monitoring

### CloudWatch Dashboard

Monitor your deployment in AWS Console:

1. Go to CloudWatch → Dashboards
2. Create dashboard with:
   - ECS Service metrics (CPU, memory, tasks)
   - ALB metrics (request count, target health)
   - Application logs

### CloudWatch Alarms

Three alarms are automatically created:

1. **CPU High** (> 80%)
   - Triggers auto-scaling
   
2. **Memory High** (> 85%)
   - Triggers auto-scaling
   
3. **ALB Unhealthy Hosts** (≥ 1)
   - Indicates task failures

### Log Insights Queries

**View application errors**:
```
fields @timestamp, @message
| filter @message like /ERROR|error|Exception/
| stats count() as errors by bin(5m)
```

**Request count per 5 minutes**:
```
fields @timestamp
| stats count() as request_count by bin(5m)
```

**Health check status**:
```
fields @timestamp, @message
| filter @message like /health/
| stats count() as health_checks by bin(5m)
```

---

## 📖 Documentation

Comprehensive documentation is included:

| Document | Purpose |
|----------|---------|
| **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** | Complete deployment guide with architecture, prerequisites, troubleshooting |
| **[CICD_QUICK_REFERENCE.md](CICD_QUICK_REFERENCE.md)** | Quick reference, checklists, configuration customization |
| **[ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md)** | Dev/Staging/Production configurations, multi-region setup |
| **[HEALTH_CHECK_GUIDE.md](HEALTH_CHECK_GUIDE.md)** | Health endpoint implementation, testing, monitoring |
| **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** | Project overview, checklist, usage examples |

### Key Sections

- Getting Started
- Architecture Overview
- AWS Resources
- Troubleshooting Guide
- Security Best Practices
- Cost Optimization
- Monitoring & Maintenance
- Disaster Recovery

---

## 🔧 Configuration

### Customize Task Resources

Edit `infrastructure/terraform.tfvars`:

```hcl
ecs_task_cpu    = 512      # Increase for more CPU
ecs_task_memory = 1024     # Increase for more memory
ecs_task_count  = 2        # Minimum number of tasks
```

### Adjust Auto-scaling

```hcl
auto_scaling_min_capacity       = 1    # Minimum tasks
auto_scaling_max_capacity       = 4    # Maximum tasks
cpu_target_tracking_value       = 70   # Scale at 70% CPU
memory_target_tracking_value    = 80   # Scale at 80% memory
```

### Environment-Specific Configs

See [ENVIRONMENT_CONFIG.md](ENVIRONMENT_CONFIG.md) for:
- Development configuration
- Staging configuration
- Production configuration
- Multi-region setup

---

## 🔐 Security Best Practices

### Implemented Security Measures

✅ Non-root container user  
✅ Private subnets for application  
✅ S3 encryption (AES256)  
✅ S3 versioning enabled  
✅ Public access blocked  
✅ Security group isolation  
✅ IAM least privilege  
✅ Health checks  
✅ Image scanning  

### Additional Recommendations

1. **Rotate AWS Credentials** every 90 days
2. **Use AWS Secrets Manager** for sensitive data
3. **Enable CloudTrail** for audit logging
4. **Implement WAF** for ALB (optional)
5. **Use HTTPS/TLS** (update ALB listener)
6. **Enable VPC Flow Logs** for network monitoring

---

## 💰 Cost Optimization

### Cost-Saving Strategies

1. **Use FARGATE_SPOT** for non-critical workloads
   - Up to 70% cost savings
   - Configure in `infrastructure/ecs.tf`

2. **Adjust Auto-scaling**
   - Reduce `auto_scaling_max_capacity` if over-provisioned
   - Monitor actual resource usage

3. **Optimize Task Resources**
   - Start with smaller tasks (256 CPU, 512 MB memory)
   - Scale up based on metrics

4. **Enable ECR Lifecycle Policies**
   - Automatically delete old images
   - Configured in `infrastructure/ecr.tf`

### Estimated Monthly Costs (Minimum)

- **ECS Fargate** (2 tasks × 512 CPU, 1GB): ~$50
- **ALB**: ~$20
- **NAT Gateway**: ~$45
- **ECR Storage**: ~$5
- **CloudWatch Logs**: ~$5

**Total**: ~$125/month (before data transfer)

---

## 🛠️ Troubleshooting

### Common Issues

#### Deployment Fails at Testing
- Check test logs: `npm test`
- Verify dependencies are installed
- Review error messages in GitHub Actions

#### Terraform Validation Fails
- Run `terraform validate` locally
- Check variable types and values
- Verify AWS credentials

#### ECS Tasks Not Healthy
- Check CloudWatch logs: `/ecs/devops-app-production`
- Verify health endpoint: `curl http://localhost:3000/health`
- Check security group rules

#### ALB Reports Unhealthy Targets
- Verify application is running
- Check health check path and timeout
- Review ECS task logs
- Verify port configuration

For detailed troubleshooting, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting).

---

## 🤝 Contributing

### Development Workflow

```bash
# Create feature branch
git checkout -b feature/your-feature develop

# Make changes and test locally
npm test

# Build Docker image locally
docker build -t devops-app:test .

# Commit changes
git add .
git commit -m "Feature: Description of changes"

# Push and create PR
git push origin feature/your-feature

# Create Pull Request to develop branch
# After review and approval, merge to main for deployment
```

### Testing Requirements

All changes must pass:
- Unit tests
- Integration tests
- E2E tests
- Docker build
- Terraform validation

---

## 📋 Checklist for First Deployment

- [ ] Fork/clone repository
- [ ] Configure GitHub secrets (AWS credentials, region)
- [ ] Add `/health` endpoint to backend
- [ ] Review DEPLOYMENT_GUIDE.md
- [ ] Validate Terraform locally
- [ ] Push to main branch
- [ ] Monitor GitHub Actions workflow
- [ ] Verify ECS service is running
- [ ] Test application health endpoint
- [ ] Set up CloudWatch dashboard
- [ ] Configure SNS alerts (optional)
- [ ] Test auto-scaling

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/launch_types.html)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [AWS Security Best Practices](https://aws.amazon.com/security/best-practices/)

---

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 📧 Support

For issues, questions, or suggestions:

1. Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md#troubleshooting)
2. Review GitHub Actions logs
3. Check CloudWatch logs
4. Verify AWS resource status

---

**Last Updated**: May 4, 2026  
**Version**: 1.0  
**Maintained By**: DevOps Team