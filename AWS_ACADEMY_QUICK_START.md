# Quick Start Guide: Deploying to AWS Academy LabRole

This guide helps you deploy the infrastructure to AWS Academy or other restricted IAM environments.

## ⚡ Quick Steps

### Step 1: Get Your LabRole ARN
```bash
# In AWS Console or CLI:
aws iam get-role --role-name LabRole --query 'Role.Arn' --output text

# Output will look like:
# arn:aws:iam::123456789012:role/LabRole
```

### Step 2: Update Configuration
Edit `infrastructure/terraform.tfvars` and uncomment/update these lines:
```hcl
ecs_task_execution_role_arn = "arn:aws:iam::123456789012:role/LabRole"
ecs_task_role_arn           = "arn:aws:iam::123456789012:role/LabRole"
autoscaling_role_arn        = "arn:aws:iam::123456789012:role/LabRole"
```

### Step 3: Validate & Deploy
```bash
cd infrastructure

# Initialize Terraform (first time only)
terraform init

# Validate configuration
terraform validate
# Output: Success! The configuration is valid.

# Review changes
terraform plan

# Deploy
terraform apply
```

## 🔍 Verification Checklist

- [ ] LabRole ARN is correct
- [ ] `terraform validate` shows no errors
- [ ] `terraform plan` shows ~32 resources to create (not IAM roles)
- [ ] ALB is created and healthy
- [ ] ECS cluster is running
- [ ] CloudWatch logs are populated

## 📋 IAM Permissions Required for LabRole

The LabRole must have these permissions:

| Service | Permissions |
|---------|-------------|
| **EC2** | `ec2:CreateVpc`, `ec2:CreateSubnet`, `ec2:CreateSecurityGroup`, `ec2:*` (most) |
| **ECS** | `ecs:CreateCluster`, `ecs:RegisterTaskDefinition`, `ecs:CreateService` |
| **ELB** | `elasticloadbalancing:CreateLoadBalancer`, `elasticloadbalancing:*` |
| **CloudWatch** | `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` |
| **ECR** | `ecr:CreateRepository`, `ecr:*` (but NOT `inspector2:*`) |
| **App Auto Scaling** | `application-autoscaling:RegisterScalableTarget`, `application-autoscaling:*` |

## ❌ What Will Fail (Missing Permissions)

If you see these errors, the LabRole may not have the required permissions:

```
Error: Error creating EC2 VPC: UnauthorizedOperation
Error: Error creating ECS Cluster: AccessDenied
Error: Error creating Load Balancer: AuthFailure
```

**Solution:** Contact your AWS Academy instructor or IT support.

## ✅ What to Expect

```bash
$ terraform apply
# ...
Apply complete! Resources added: 32.

Outputs:
alb_dns_name = "devops-alb-12345.us-east-1.elb.amazonaws.com"
ecs_cluster_name = "devops-cluster"
application_url = "http://devops-alb-12345.us-east-1.elb.amazonaws.com"
```

## 🐛 Troubleshooting

### Q: "User is not authorized to perform: iam:CreateRole"
**A:** This is expected in AWS Academy. You've configured the role ARNs correctly. This message means Terraform tried to create a role but the LabRole doesn't have permission. Verify your `terraform.tfvars` has non-empty role ARNs.

### Q: "error creating Network ACL rule: NetworkAclEntryAlreadyExists"
**A:** This was fixed in this version. If you see it, run `terraform validate` to confirm you have the latest code.

### Q: "InvalidParameterValue" when creating ECS tasks
**A:** The LabRole may not have permissions to assume service roles. Contact your instructor.

### Q: ALB is created but no tasks are running
**A:** Check CloudWatch logs: `aws logs tail /ecs/devops-app-production --follow`

## 📞 Need Help?

1. **Check Terraform outputs:** `terraform output`
2. **Check CloudWatch logs:** `aws logs describe-log-groups`
3. **Check ECS service status:** `aws ecs describe-services --cluster devops-cluster --services devops-service`
4. **Check IAM permissions:** `aws iam get-user` and verify role is `LabRole`

## 🔄 Updating Later

If you need to redeploy:

```bash
# Plan changes
terraform plan

# Apply only specific resources (e.g., just update ECS)
terraform apply -target='aws_ecs_task_definition.app'

# Destroy everything (WARNING: This is destructive)
terraform destroy
```

## 💡 Pro Tips

- **Auto-approve in CI/CD:** `terraform apply -auto-approve`
- **Output variables for scripts:** `terraform output -json`
- **Save plan for later:** `terraform plan -out=tfplan && terraform apply tfplan`
- **Dry run:** `terraform plan` (doesn't create anything)

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/best_practices.html)
- [AWS Academy Support](https://awseducate.brightspace.com)

---

**Last Updated:** May 5, 2026
