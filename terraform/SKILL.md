---
name: terraform
description: Design and manage infrastructure as code with Terraform. Covers project structure, module design, remote state (S3 + DynamoDB), workspace vs directory isolation, moved blocks for refactoring, CI/CD pipelines with plan/apply separation, and emergency state surgery. Use when user asks to write Terraform config, set up remote state, design modules, manage state, or automate infrastructure. Triggers on "terraform", "infrastructure as code", "IaC", "state management", "remote backend", "module", "HCL", "plan", "apply". Do NOT use for Kubernetes manifests, Dockerfiles, or CI/CD pipeline config — those have their own skills.
license: MIT
compatibility: opencode
metadata:
  workflow: infrastructure
  audience: devops
---

Design, manage, and operate infrastructure as code with Terraform. Covers project structure, module design, state management, and CI/CD integration.

## Workflow

### Step 1: Determine project structure

| Scale | Structure | State Strategy |
|-------|-----------|---------------|
| Personal project | Single `main.tf` | Remote backend, optional workspaces |
| Team (2-5) | `envs/{dev,staging,prod}/` + `modules/` | Directory-per-environment, separate backends |
| Platform team | `infra/{networking,compute,data,iam}/` per repo | Per-component state files, `terraform_remote_state` for cross-refs |

### Step 2: Bootstrap remote backend

```hcl
# backend.tf — bootstrap once, store state in S3 + DynamoDB lock
terraform {
  backend "s3" {
    bucket         = "tf-state-{account}-{region}"
    key            = "{env}/{component}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "tf-state-lock"
  }
  required_version = ">= 1.9"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
```

### Step 3: Design modules

Module single responsibility: one module = one domain (networking, compute, database, IAM).

```
modules/
├ networking/
│   main.tf
│   variables.tf
│   outputs.tf
├ compute/
│   main.tf
│   variables.tf
│   outputs.tf
└ database/
    main.tf
    variables.tf
    outputs.tf
environments/
├ prod/
│   backend.tf    # key = "prod/compute/terraform.tfstate"
│   main.tf       # module "compute" { source = "../../modules/compute" ... }
│   terraform.tfvars
└ dev/
    ├ backend.tf  # key = "dev/compute/terraform.tfstate"
    ├ main.tf
    └ terraform.tfvars
```

### Step 4: Write production module guidelines

- **Single responsibility**: One module handles one domain
- **Sensible defaults**: Secure by default, require explicit opt-out for insecure configs
- **Input validation**: `validation { condition = ... }` on all variables
- **Outputs**: Only what consumers need via `terraform_remote_state`
- **Versioning**: Pin module version via git tag or registry

## State Management Rules

| Rule | Why |
|------|-----|
| Remote state always | Local state is single-player. Team = remote. |
| S3 + DynamoDB | S3 stores, DynamoDB locks. Standard. |
| Versioning on state bucket | Rollback from bad apply in 30 seconds. |
| KMS encryption | State files contain secrets in plaintext. |
| Per-environment isolation | A `terraform destroy` in dev should never touch prod. |
| Per-component state | Change to IAM should not re-evaluate RDS. |
| Directory-per-environment preferred | Workspaces share backend — too easy to `select prod` by accident. |
| `moved` blocks over `state rm/mv` | Code-reviewed, reversible, self-documenting. |

## moved Block (for refactoring)

```hcl
# When you move a resource from one module to another
moved {
  from = aws_s3_bucket.old
  to   = module.storage.aws_s3_bucket.main
}

# When you rename a resource
moved {
  from = aws_instance.web
  to   = aws_instance.app
}
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
| Remove resource from state (not destroy) | `terraform state rm <address>` |
| Import existing resource into state | `terraform import <address> <id>` |
| Move resource in state (refactoring) | `terraform state mv <from> <to>` |
| Unlock stuck state | `terraform force-unlock <lock-id>` |
| Rollback corrupted state | Restore previous version from S3 versioning |
| List resources in state | `terraform state list` |
| Show resource details | `terraform state show <address>` |

## Production Checklist

- [ ] Remote backend with S3 + DynamoDB locking
- [ ] KMS encryption on state bucket
- [ ] Versioning enabled on state bucket
- [ ] Public access blocked on state bucket
- [ ] Per-environment state isolation (directory approach preferred)
- [ ] Per-component state files (not one monolith)
- [ ] State access IAM roles follow least privilege
- [ ] Plan runs on PR, apply only from CI
- [ ] `concurrency` key prevents simultaneous applies
- [ ] `terraform validate` + `fmt -check` in CI
- [ ] Module versions pinned (not `latest`)
- [ ] Secrets use `sensitive = true` on outputs
- [ ] No secrets in state (use Vault / AWS Secrets Manager)

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
