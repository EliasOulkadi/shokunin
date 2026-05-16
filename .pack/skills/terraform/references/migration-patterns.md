# Terraform Migration Patterns

Production infrastructure evolves. These patterns cover the common state
migrations you'll encounter.

## Decision Tree

```
Need to rename/move a resource?        → moved block
Need to extract a resource to a module? → moved block with module address
Need to delete a resource but keep it?  → removed block
Need to import existing infra?          → terraform import
Need to split a state file?             → terraform state mv to new backend
Need to merge state files?              → terraform state mv into same state
```

## 1. Moved Blocks (Preferred)

Always prefer `moved` blocks over manual `state mv`. They're code-reviewed,
reversible, and self-documenting.

### Rename a Resource

```hcl
# Before
resource "aws_s3_bucket" "old_name" {
  bucket = "my-app-data"
}

# After
resource "aws_s3_bucket" "new_name" {
  bucket = "my-app-data"
}

moved {
  from = aws_s3_bucket.old_name
  to   = aws_s3_bucket.new_name
}
```

### Move a Resource into a Module

```hcl
# Before: resource was at root
resource "aws_s3_bucket" "data" {
  bucket = "my-app-data"
}

# After: moved to module
module "storage" {
  source = "../../modules/storage"
}

moved {
  from = aws_s3_bucket.data
  to   = module.storage.aws_s3_bucket.data
}
```

### Move Between Module Instances

```hcl
# Before
module "app" {
  source = "./modules/app"
  count  = 2
}

# After: changed to for_each
module "app" {
  source   = "./modules/app"
  for_each = toset(["a", "b"])
}

moved {
  from = module.app[0]
  to   = module.app["a"]
}

moved {
  from = module.app[1]
  to   = module.app["b"]
}
```

## 2. Removed Blocks

Removes a resource from state without destroying the real infrastructure.

```hcl
resource "aws_instance" "legacy" {
  # ... config kept for reference, will be deleted from config later
}

removed {
  from = aws_instance.legacy

  lifecycle {
    destroy = false
  }
}
```

After applying, the resource is gone from state. You can then delete the
`removed` block and the resource configuration.

Use cases:
- Decommissioning a Terraform-managed resource but keeping it running
- Handing off management to another team/process
- Cleaning up state after migrating to a different module structure

## 3. Split a State File

When a state file grows too large or you need per-component isolation.

### Extract a component using `terraform state mv`

```bash
# 1. Create the new backend config
cat > new-backend.tf <<'EOF'
terraform {
  backend "s3" {
    bucket = "tf-state-prod"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}
EOF

# 2. Init with the NEW backend (empty state)
terraform init -reconfigure -migrate-state

# 3. Plan to see what's in the new state (should be empty)
terraform state list

# 4. Go back to original backend
terraform init -reconfigure -migrate-state

# 5. Move resources to the new backend
terraform state mv -state-out=networking.tfstate \
  aws_vpc.main aws_vpc.main

terraform state mv -state-out=networking.tfstate \
  aws_subnet.public aws_subnet.public

# 6. Upload networking.tfstate to the networking backend path
# 7. Remove networking resources from original config
# 8. Add terraform_remote_state data source to reference them
```

### Safer approach (recommended): Dual run

```bash
# Day 1: Add removed blocks + new backend config
#         1. In old root: add removed { from = ... lifecycle { destroy = false } }
#         2. Create new component directory with terraform_remote_state data source
#         3. Apply old root — removes resources from state, keeps infra
#         4. terraform import in new component directory
#
# Day 2: Clean up
#         1. Remove old resource configs
#         2. Remove removed blocks
```

## 4. Import Existing Resources

```bash
# Standard import
terraform import aws_s3_bucket.data my-app-data

# Import into a module (Terraform 1.5+)
terraform import module.storage.aws_s3_bucket.data my-app-data

# Bulk import with config generation (Terraform 1.5+)
# Write the resource address, terraform generates the config skeleton
terraform add aws_instance.web
# Then import
terraform import aws_instance.web i-1234567890abcdef0
```

### Import Pattern with Config

```hcl
# Step 1: Write the resource shell
resource "aws_instance" "web" {
  # leave empty — terraform import fills state
}

# Step 2: Import
# terraform import aws_instance.web i-1234567890abcdef0

# Step 3: Verify state
# terraform state show aws_instance.web

# Step 4: Write config matching the real resource
resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.large"

  tags = {
    Name = "web-server"
  }

  # Imported state already has the id, so this won't recreate
}

# Step 5: Plan to verify no changes
# terraform plan
```

## 5. Merge State Files

```bash
# Create a temp directory with the destination backend config
mkdir -p merge-temp
cd merge-temp

cat > backend.tf <<'EOF'
terraform {
  backend "s3" {
    bucket = "tf-state-prod"
    key    = "merged/terraform.tfstate"
    region = "us-east-1"
  }
}
EOF

terraform init

# Pull the source states
terraform state pull > /tmp/destination.tfstate
terraform state pull -state=networking.tfstate > /tmp/source.tfstate

# Push the merged state
terraform state push /tmp/destination.tfstate

# Move resources from source to destination
terraform state mv \
  -state=/tmp/source.tfstate \
  -state-out=/tmp/destination.tfstate \
  aws_vpc.main aws_vpc.main

# Push the merged result
terraform state push /tmp/destination.tfstate
```

## 6. Refactoring Modules

### Split a Module

```hcl
# Before: monolithic module
module "infra" {
  source = "../../modules/infra"
}

# After: split into focused modules
module "networking" {
  source = "../../modules/networking"
  vpc_cidr = var.vpc_cidr
}

module "compute" {
  source = "../../modules/compute"
  vpc_id = module.networking.outputs.vpc_id
}

# Moved blocks in compute module
moved {
  from = module.infra.aws_instance.app
  to   = aws_instance.app
}
```

### Inline to Module

```hcl
# Before: inline resource
resource "aws_iam_role" "app" {
  name = "app-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# After: in module
module "iam" {
  source = "../../modules/iam"
  role_name = "app-role"
}

# Moved block in root
moved {
  from = aws_iam_role.app
  to   = module.iam.aws_iam_role.this
}
```

## 7. Provider or Region Migration

```hcl
# Example: Move AWS resource from us-east-1 to us-west-2
# Step 1: Add the new provider to the config
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# Step 2: Duplicate the resource with the new provider
resource "aws_s3_bucket" "data_west" {
  provider = aws.west
  bucket   = "my-app-data-west"
}

# Step 3: Apply (creates new bucket in us-west-2)

# Step 4: Copy data, update DNS, etc.

# Step 5: Remove old resource
removed {
  from = aws_s3_bucket.data
  lifecycle {
    destroy = false
  }
}

# Step 6: Apply again (removes from state, leaves bucket in us-east-1)
```

## Quick Reference

| Task | Command / Block |
|------|----------------|
| Rename resource | `moved { from = X to = Y }` |
| Move into module | `moved { from = X to = module.M.X }` |
| Remove from state (keep infra) | `removed { from = X lifecycle { destroy = false } }` |
| Import single resource | `terraform import <address> <id>` |
| Import into module | `terraform import module.M.<address> <id>` |
| Move between workspaces | `terraform state mv -state-out=<path> <from> <to>` |
| Split state file | `terraform state mv -state-out=<path>` |
| Merge state files | `terraform state push`, then `state mv` across files |
| List resources in state | `terraform state list` |
| Show resource details | `terraform state show <address>` |
| Check for moved blocks | `terraform plan` shows "Moved" in output |
