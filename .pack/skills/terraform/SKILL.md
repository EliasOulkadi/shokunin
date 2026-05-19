---
name: terraform
description: Design and manage infrastructure as code with Terraform — modules, remote state (S3 + DynamoDB), Stacks (deployments), test framework, preconditions/postconditions, moved/removed blocks, and CI/CD plan/apply separation. Use when user asks to write Terraform config, set up remote state, design modules, manage state, or automate infrastructure. Do NOT use for Kubernetes (use kubernetes), Docker (use docker), or CI/CD pipeline design (use ci-cd).
triggers:
  - "Terraform"
  - "infrastructure as code"
  - "IaC"
  - "terraform plan"
  - "terraform apply"
  - "terraform state"
  - "remote backend"
  - "provision infrastructure"
  - "cloud resources"
  - "AWS infrastructure"
  - "HashiCorp"
  - "terraform module"
negatives:
  - "Kubernetes"
  - "Docker"
  - "CI/CD"
  - "Ansible"
  - "Pulumi"
  - "CloudFormation"
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
  version: "2.0.0"
---


# Terraform Architect

Design infrastructure as code with Terraform 1.10+ features: Stacks, test framework, provider-defined functions, and state management.

## Workflow

### Step 1: Determine project structure

| Scale | Structure | State Strategy |
|-------|-----------|---------------|
| Personal | Single `main.tf` | Remote backend, optional workspaces |
| Team (2-5) | `envs/{dev,prod}/modules/` | Directory-per-environment, separate backends |
| Platform team | `infra/{networking,compute,data,iam}/` per repo | Per-component state, `terraform_remote_state` |

### Step 2: Bootstrap remote backend

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "tf-state-{account}-{region}"
    key            = "{env}/{component}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-lock"
  }
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
```

### Step 3: Design modules

Single responsibility: one module = one domain.

```
modules/
├ networking/
│   main.tf, variables.tf, outputs.tf
├ compute/
│   main.tf, variables.tf, outputs.tf
└ database/
    main.tf, variables.tf, outputs.tf
environments/
├ prod/
│   backend.tf -> key = "prod/compute/terraform.tfstate"
│   main.tf       module "compute" { source = "../../modules/compute" }
│   terraform.tfvars
└ dev/
```

### Step 4: Use preconditions/postconditions

```hcl
resource "aws_db_instance" "main" {
  allocated_storage = 100
  engine = "postgres"
  engine_version = "16.3"
  instance_class = "db.r6g.large"

  lifecycle {
    postcondition {
      condition     = self.engine == "postgres"
      error_message = "Only PostgreSQL is supported"
    }
  }
}

data "aws_iam_policy_document" "example" {
  statement {
    actions = ["s3:GetObject"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }

    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = var.allowed_ips
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.allowed_ips) > 0
      error_message = "At least one allowed IP must be specified"
    }
  }
}
```

### Step 5: Use moved and removed blocks for refactoring

```hcl
# Instead of manual state mv, code-review it:
moved {
  from = aws_s3_bucket.old
  to   = module.storage.aws_s3_bucket.main
}

# To remove a resource from state without destroying it:
removed {
  from = aws_instance.legacy
  lifecycle {
    destroy = false  # Keep the resource alive
  }
}
```

## Terraform Stacks (2025+)

Stacks enable deployment of multiple configurations with shared state:

```hcl
# stacks/stack.hcl
stack "dev" {
  source = "./infrastructure"
  path   = "dev"
}

stack "prod" {
  source = "./infrastructure"
  path   = "prod"
}
```

## Provider-defined Functions (1.10+)

```hcl
# Built-in providers now expose functions
result = provider::aws::arn_parse("arn:aws:s3:::my-bucket")
# or
result = provider::aws::arn_build("s3", "my-bucket", "", "us-east-1")
```

## Testing Framework

```hcl
# tests/example.tftest.hcl
run "create_bucket" {
  command = apply
  variables {
    bucket_name = "test-bucket-${run_id}"
  }
  assert {
    condition     = aws_s3_bucket.main.bucket == "test-bucket-${run_id}"
    error_message = "Bucket name mismatch"
  }
}

run "verify_encryption" {
  command = apply
  assert {
    condition     = aws_s3_bucket.main.server_side_encryption_configuration[0].rule[0].apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"
    error_message = "Bucket must have AES256 encryption"
  }
}
```

```bash
terraform test
```

## State Management Rules

| Rule | Why |
|------|-----|
| Remote state always | Local is single-player |
| S3 + DynamoDB | Standard state storage + locking |
| Versioning on state bucket | Rollback bad apply |
| KMS encryption | State files contain secrets |
| Per-environment isolation | `destroy` in dev should never touch prod |
| Per-component state | Change IAM should not re-evaluate RDS |
| Directory-per-environment preferred | Workspaces share backend — too easy to select prod by accident |
| `moved` blocks over `state rm/mv` | Code-reviewed, reversible, self-documenting |

## Provider Caching (CI speedup)

```bash
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# Share cache across projects
mkdir -p $TF_PLUGIN_CACHE_DIR
```

## CI/CD Pipeline

```yaml
name: Terraform
on: [pull_request, push]
jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - run: terraform fmt -check
      - run: terraform validate
      - run: terraform plan -out=tfplan
      - uses: actions/upload-artifact@v4
        with: { name: tfplan, path: tfplan }

  apply:
    if: github.ref == 'refs/heads/main'
    needs: [plan]
    runs-on: ubuntu-latest
    environment: production
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
      - run: terraform init
      - uses: actions/download-artifact@v4
        with: { name: tfplan }
      - run: terraform apply tfplan
```

## Emergency State Surgery

| Situation | Command |
|-----------|---------|
| Remove resource from state | `terraform state rm <address>` |
| Import existing resource | `terraform import <address> <id>` |
| Move resource (refactoring) | `terraform state mv <from> <to>` |
| Unlock stuck state | `terraform force-unlock <lock-id>` |
| Rollback corrupted state | Restore previous S3 version |
| List resources | `terraform state list` |
| Show resource details | `terraform state show <address>` |

## Production Checklist

- [ ] Remote backend S3 + DynamoDB locking
- [ ] KMS encryption on state bucket
- [ ] Versioning enabled on state bucket
- [ ] Public access blocked on state bucket
- [ ] Per-environment state isolation
- [ ] Per-component state files
- [ ] State access IAM roles (least privilege)
- [ ] Plan on PR, apply only from CI
- [ ] `concurrency` prevents simultaneous applies
- [ ] `terraform validate` + `fmt -check` in CI
- [ ] Module versions pinned (not `latest`)
- [ ] Secrets as `sensitive = true` on outputs
- [ ] No secrets in state (Vault / AWS Secrets Manager)

## Anti-Patterns

| Anti-pattern | Fix |
|-------------|-----|
| Local state in team project | Remote state (S3 + DynamoDB) |
| One giant state file | Split by component |
| Workspaces for env isolation | Directory-per-environment |
| Manual `state mv` instead of `moved` blocks | Code-reviewed `moved` blocks |
| `latest` provider version | Pin `~> 5.0` |
| Running `apply` from laptop | CI/CD with saved plan |
| No locking | DynamoDB table for state lock |
| Secrets in state outputs | Mark `sensitive = true`, use external secrets manager |
| No preconditions/postconditions | Add for security-critical resources |

## Plan Review Format (Required)

When reviewing `terraform plan` output, verify these checks:

| Before | After | Why |
|--------|-------|-----|
| Blind `terraform apply` without reviewing plan | Read plan output fully. Check for `forces replacement` on stateful resources (DBs, disks). | Replacement destroys and recreates the resource, losing data. Flag it before applying. |
| `latest` provider version in `required_providers` | Pin to `~> 5.0` or specific version | Provider updates can change resource defaults silently. Pin for reproducibility. |
| Local state file (`terraform.tfstate`) in team project | Remote backend with S3/GCS + DynamoDB locking | Local state causes conflicts. Remote state with locking prevents simultaneous applies. |
| Workspaces for environment isolation | Separate directories per environment or Terraform Stacks | Workspaces share the same backend and code. Accidental `terraform workspace select production` when targeting staging is a real risk. |

## Error Handling

| Scenario | Cause | Diagnosis | Fix |
|----------|-------|-----------|-----|
| State lock timeout | Another process holds the lock (CI stuck, manual apply abandoned) | `terraform force-unlock -force` will show lock ID and holder | Kill the holding process first. If process is dead, `terraform force-unlock <lock-id>`. Set `max_retries` in backend config. |
| Provider version mismatch | `required_providers` version constraint doesn't match lock file (`.terraform.lock.hcl`) | `terraform init` fails with "provider version constraints changed" | Run `terraform init -upgrade` to update lock file. Pin versions with `~>` not `>=`. Commit lock file. |
| Plan diff too large (>5000 lines) | Drift from manual console changes, or too many resources in one state file | Plan output is unreadable, review impossible | Split into smaller component state files. Use `terraform plan -target` for targeted review. Run `terraform refresh` to sync state. Consider `-parallelism=1` for slow APIs. |
| Apply timeout | API throttling, resource creation taking >30min, network issues | Apply hangs or exits with timeout error | Increase `-lock-timeout=30m`. Check cloud provider status page. Split into smaller applies. Set resource `timeouts {}` blocks. Use `TF_LOG=DEBUG` for verbose output. |
| Backend unreachable | S3 bucket deleted, IAM role expired, network partition | `terraform init` or `terraform plan` fails with "Failed to load backend" | Verify S3 bucket exists and IAM role has `s3:GetObject` + `s3:PutObject` + `dynamodb:GetItem` + `dynamodb:PutItem`. Check `~/.aws/credentials`. Restore bucket from backup if deleted. |
| Workspace inconsistency | Wrong workspace selected (`default` vs `prod`), stale plan file | Apply fails on unexpected resource diffs or destroys | Always `terraform workspace show` before plan/apply. Use directory-per-environment to eliminate workspace risk. Delete stale `.tfplan` files after apply. |

## State Surgery

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_instance.web

# Move resource between state files
terraform state mv -state-out=prod.tfstate aws_instance.web aws_instance.web

# Remove resource from state (keeps real resource)
terraform state rm aws_instance.old_server

# Import existing resource into state
terraform import aws_instance.web i-1234567890abcdef0
```

## Provider Pinning Strategy

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws"; version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes"; version = ">= 2.20, < 3.0" }
  }
}
```

Rules: `~>` for minor updates (5.0-5.x). `>= X, < Y` for explicit ranges. Never `latest`.

## Cost Estimation

```bash
# Infracost (open source)
infracost breakdown --path . --format table

# Terraform Cloud cost estimation (paid)
# Enabled automatically in Terraform Cloud workspaces

# Manual: cost per resource type
# EC2: instance_type * hours * region_price
# RDS: instance_class * hours + storage_gb * 0.115
# S3: gb_stored * 0.023 + requests * 0.0004

# Tag for cost allocation
resource "aws_instance" "web" {
  tags = { CostCenter = "engineering", Environment = "production" }
}
```

## Sources

- Terraform Documentation (developer.hashicorp.com/terraform)
- Terraform Stacks — HCP documentation
- Terraform Test Framework — developer.hashicorp.com
- HashiCorp Learn: moved blocks
- AWS Well-Architected IaC patterns
- Gruntwork — Terraform best practices

## Pre-Apply Checklist

Before `terraform apply`:

- [ ] `terraform fmt -recursive` passes — all files consistently formatted
- [ ] `terraform validate` passes — syntax and reference errors caught
- [ ] `terraform plan` reviewed — no unexpected resource replacements
- [ ] Stateful resources (RDS, S3, disks) have `prevent_destroy = true` in lifecycle block
- [ ] Remote backend configured with state locking (DynamoDB for S3, etc.)
- [ ] Provider versions pinned (`~> X.Y` or exact version), never `latest`
- [ ] Preconditions/postconditions on critical resources (e.g., `condition = var.instance_count > 0`)
- [ ] `moved` blocks for renamed resources (never `terraform state mv` manually)
- [ ] Sensitive outputs marked with `sensitive = true`
- [ ] Plan file reviewed by a second person for production changes
- [ ] `terraform apply` runs from CI/CD, not a developer laptop

## Checklist

- [ ] Skill loads without errors in the AI agent
- [ ] YAML frontmatter is valid (description, compatibility, audience)
- [ ] Workflow section provides clear step-by-step instructions
- [ ] Error handling section covers common failure modes
- [ ] All referenced files (references/, scripts/, assets/) exist
- [ ] Skill triggers correctly for intended use cases
- [ ] No broken links or missing resources
