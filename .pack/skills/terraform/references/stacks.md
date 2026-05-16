# Terraform Stacks

Introduced in Terraform 1.10 / HCP Terraform. Stacks manage deployments of
multiple infrastructure configurations with shared orchestration, state, and
output wiring — replacing the pattern of glue scripts + `terraform_remote_state`.

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Stack** | A deployable unit — one or more components with a shared deployment lifecycle |
| **Component** | A root module deployed independently, with its own state file |
| **Deployment** | An instance of a stack created with specific input values |
| **Orchestration** | Terraform resolves dependencies and applies components in order |

## When to Use Stacks vs. Directory Structure

| Approach | Good For |
|----------|----------|
| `envs/{dev,prod}/main.tf` | Small teams, 1-5 components, simple dependencies |
| **Stacks** | Platform teams, 10+ components, cross-component outputs, orchestration needs |
| `stacks/` with HCL config | CI-driven deployments with plan/apply separation per component |

## Stack Configuration (`stack.hcl`)

```hcl
# stacks/stack.hcl
stack "networking" {
  source = "./components/networking"
  path   = "networking"

  inputs = {
    vpc_cidr        = "10.0.0.0/16"
    environment     = var.environment
    enable_nat      = var.enable_nat_gateway
  }
}

stack "compute" {
  source = "./components/compute"
  path   = "compute"

  # Orchestration: compute depends on networking outputs
  inputs = {
    vpc_id          = stack.networking.outputs.vpc_id
    subnet_ids      = stack.networking.outputs.private_subnet_ids
    environment     = var.environment
  }
}

stack "database" {
  source = "./components/database"
  path   = "database"

  inputs = {
    vpc_id          = stack.networking.outputs.vpc_id
    subnet_ids      = stack.networking.outputs.data_subnet_ids
    environment     = var.environment
  }
}
```

## Variables and Outputs

Stacks support a `stacks` block for passing outputs between components:

```hcl
# stack.hcl — variable declaration
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod"
  }
}

variable "enable_nat_gateway" {
  type    = bool
  default = true
}

# stack.hcl — orchestrator outputs
output "vpc_id" {
  value = stack.networking.outputs.vpc_id
}

output "cluster_endpoint" {
  value = stack.database.outputs.endpoint
}
```

## Deploying Stacks

```bash
# Create a new deployment
terraform stacks deploy stacks/base.hcl -name=my-deployment

# List deployments
terraform stacks list

# Plan changes for a deployment
terraform stacks plan <deployment-id>

# Apply
terraform stacks apply <deployment-id>

# Destroy
terraform stacks destroy <deployment-id>
```

## CI/CD with Stacks

```yaml
jobs:
  plan:
    steps:
      - run: |
          for stack in stacks/*.hcl; do
            name=$(basename $stack .hcl)
            terraform stacks plan $name -out=plans/$name.tfplan
          done

  apply:
    if: github.ref == 'refs/heads/main'
    steps:
      - run: |
          for plan in plans/*.tfplan; do
            terraform stacks apply $(basename $plan .tfplan)
          done
```

## Stack Composition Patterns

### 1. Multi-region Deployment

```hcl
stack "app_us_east_1" {
  source = "./components/app"
  path   = "us-east-1"

  providers = {
    aws = provider::aws::us_east_1
  }

  inputs = {
    region      = "us-east-1"
    environment = var.environment
  }
}

stack "app_eu_west_1" {
  source = "./components/app"
  path   = "eu-west-1"

  providers = {
    aws = provider::aws::eu_west_1
  }

  inputs = {
    region      = "eu-west-1"
    environment = var.environment
  }
}
```

### 2. Blue/Green Deployment Orchestration

```hcl
variable "active_color" {
  type    = string
  default = "blue"
}

stack "blue" {
  source = "./components/service"
  path   = "blue"

  inputs = {
    color      = "blue"
    dns_weight = var.active_color == "blue" ? 100 : 0
  }
}

stack "green" {
  source = "./components/service"
  path   = "green"

  inputs = {
    color      = "green"
    dns_weight = var.active_color == "green" ? 100 : 0
  }
}
```

### 3. Layered Infrastructure

```hcl
# Foundation — base account-wide resources
stack "foundation" {
  source = "./components/foundation"
  path   = "foundation"

  inputs = {
    organization = var.organization
  }
}

# Security — depends on foundation
stack "security" {
  source = "./components/security"
  path   = "security"

  inputs = {
    audit_log_bucket = stack.foundation.outputs.audit_log_bucket
    kms_key_ids      = stack.foundation.outputs.kms_key_ids
  }
}

# Services — depends on both
stack "services" {
  source = "./components/services"
  path   = "services"

  inputs = {
    network_config        = stack.foundation.outputs.network_config
    security_group_ids    = stack.security.outputs.security_group_ids
  }
}
```

## Limitations (as of 1.10)

- Stacks require HCP Terraform or Terraform CLI 1.10+
- No partial applies — a stack deployment applies all its components
- Component outputs are only available within the stack, not externally
- Dynamic provider configurations per component require explicit provider declarations
- State operations (import, mv, rm) operate on individual components, not the stack
