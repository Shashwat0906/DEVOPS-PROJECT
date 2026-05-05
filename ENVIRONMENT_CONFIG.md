# Example Environment-Specific Terraform Configurations

This file demonstrates how to create environment-specific Terraform variable files
for different deployment stages.

## File Structure

```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── networking.tf
├── ecr.tf
├── iam.tf
├── ecs.tf
├── terraform.tfvars           # Default (production)
├── terraform.dev.tfvars       # Development
├── terraform.staging.tfvars   # Staging
└── .gitignore
```

## Usage

### Apply Production (main branch)
```bash
cd infrastructure
terraform apply -var-file=terraform.tfvars
```

### Apply Staging
```bash
cd infrastructure
terraform apply -var-file=terraform.staging.tfvars
```

### Apply Development
```bash
cd infrastructure
terraform apply -var-file=terraform.dev.tfvars
```

## Environment-Specific Configurations

### Development (terraform.dev.tfvars)

```hcl
aws_region       = "us-east-1"
project_name     = "devops-app"
environment      = "dev"

# Minimal resources for cost savings
ecs_task_cpu     = 256
ecs_task_memory  = 512
ecs_task_count   = 1  # Single task for dev

# Auto-scaling disabled in dev
auto_scaling_min_capacity = 1
auto_scaling_max_capacity = 1

# Shorter log retention
log_retention_days = 7

tags = {
  Environment = "development"
  CostCenter  = "Development"
  Team        = "DevOps"
}
```

### Staging (terraform.staging.tfvars)

```hcl
aws_region       = "us-east-1"
project_name     = "devops-app"
environment      = "staging"

# Medium-sized resources
ecs_task_cpu     = 512
ecs_task_memory  = 1024
ecs_task_count   = 2

# Conservative auto-scaling
auto_scaling_min_capacity = 1
auto_scaling_max_capacity = 2

# Medium log retention
log_retention_days = 14

# Reduce health check sensitivity
health_check_interval             = 30
health_check_healthy_threshold    = 3
health_check_unhealthy_threshold  = 2

# Conservative scaling thresholds
cpu_target_tracking_value    = 75
memory_target_tracking_value = 85

tags = {
  Environment = "staging"
  CostCenter  = "Staging"
  Team        = "DevOps"
}
```

### Production (terraform.tfvars)

```hcl
aws_region       = "us-east-1"
project_name     = "devops-app"
environment      = "production"

# Optimal resources for production
ecs_task_cpu     = 512
ecs_task_memory  = 1024
ecs_task_count   = 2  # Minimum for high availability

# Aggressive auto-scaling
auto_scaling_min_capacity = 2
auto_scaling_max_capacity = 4

# Extended log retention
log_retention_days = 30

# Strict health checks
health_check_interval             = 30
health_check_timeout              = 5
health_check_healthy_threshold    = 2
health_check_unhealthy_threshold  = 3

# Balanced scaling thresholds
cpu_target_tracking_value    = 70
memory_target_tracking_value = 80

tags = {
  Environment = "production"
  CostCenter  = "Production"
  Team        = "DevOps"
  Criticality = "high"
}
```

## Advanced: Using Environment Variables

You can also use environment variables with Terraform:

```bash
# Set environment-specific variables
export TF_VAR_environment="production"
export TF_VAR_ecs_task_cpu="512"
export TF_VAR_ecs_task_memory="1024"
export TF_VAR_ecs_task_count="2"

# Apply without -var-file
terraform apply
```

## AWS Region-Specific Configuration

### Multi-Region Deployment

Create regional configurations:

```
infrastructure/
├── terraform.tfvars           # us-east-1 (primary)
├── terraform.eu-west-1.tfvars # Europe
├── terraform.ap-south-1.tfvars # Asia Pacific
```

### Example: Europe (terraform.eu-west-1.tfvars)

```hcl
aws_region       = "eu-west-1"
project_name     = "devops-app"
environment      = "production"

# VPC CIDR for Europe region
vpc_cidr              = "10.1.0.0/16"
availability_zones    = ["eu-west-1a", "eu-west-1b"]
public_subnet_cidrs   = ["10.1.10.0/24", "10.1.11.0/24"]
private_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]

# Same compute configuration
ecs_task_cpu     = 512
ecs_task_memory  = 1024
ecs_task_count   = 2

tags = {
  Region  = "eu-west-1"
  Country = "Ireland"
  Team    = "DevOps"
}
```

## GitHub Actions Integration

Update `.github/workflows/deploy.yml` to use environment-specific configs:

```yaml
env:
  # Determine tfvars file based on branch
  TFVARS_FILE: |
    ${{ github.ref == 'refs/heads/main' && 'terraform.tfvars' || 
        github.ref == 'refs/heads/staging' && 'terraform.staging.tfvars' || 
        'terraform.dev.tfvars' }}

jobs:
  terraform:
    steps:
      - name: Terraform plan
        run: |
          cd infrastructure
          terraform plan -var-file=${{ env.TFVARS_FILE }} -out=tfplan

      - name: Terraform apply
        if: github.ref == 'refs/heads/main'
        run: |
          cd infrastructure
          terraform apply -var-file=${{ env.TFVARS_FILE }} -auto-approve tfplan
```

## Workspace Alternative (Advanced)

Terraform workspaces allow managing multiple environments:

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new staging

# Switch workspace
terraform workspace select staging

# Apply with workspace
terraform apply -var-file=variables.tfvars
```

## Best Practices

1. **Use separate state files** for each environment:
   - Development: `dev/terraform.tfstate`
   - Staging: `staging/terraform.tfstate`
   - Production: `prod/terraform.tfstate`

2. **Version control -var-files**:
   - Commit `*.tfvars` files
   - Exclude `terraform.tfvars.secret` (sensitive values)

3. **Use backend configuration** for state:
   ```bash
   terraform init \
     -backend-config="bucket=terraform-state" \
     -backend-config="key=${ENVIRONMENT}/terraform.tfstate"
   ```

4. **Separate sensitive variables**:
   ```bash
   # terraform.secret.tfvars (in .gitignore)
   db_password = "sensitive_password"
   api_key     = "secret_key"
   ```

5. **Validate before applying**:
   ```bash
   terraform validate
   terraform fmt -check
   terraform plan -var-file=terraform.tfvars
   ```

## Cost Estimation

Estimate costs for different environments:

```bash
# Production (estimated)
cd infrastructure
terraform plan -var-file=terraform.tfvars -json | \
  grep -i "estimated"

# Staging (lower cost)
terraform plan -var-file=terraform.staging.tfvars -json

# Development (minimal cost)
terraform plan -var-file=terraform.dev.tfvars -json
```

## Rollback Procedure

Rollback to previous infrastructure state:

```bash
# List backups (if versioning enabled)
aws s3api list-object-versions \
  --bucket terraform-state-bucket \
  --prefix ${ENVIRONMENT}/terraform.tfstate

# Get specific version
aws s3api get-object \
  --bucket terraform-state-bucket \
  --key ${ENVIRONMENT}/terraform.tfstate \
  --version-id VersionIdHere \
  terraform.tfstate.backup

# Apply previous state
terraform apply -var-file=terraform.${ENVIRONMENT}.tfvars \
  -state=terraform.tfstate.backup
```

