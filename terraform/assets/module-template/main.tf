# main.tf — Module template
# Copy this directory as a starting point for new modules.

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_kms_alias" "this" {
  name_prefix   = "alias/${var.name}-"
  target_key_id = aws_kms_key.this.id
}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = var.enable_key_rotation
  policy                  = data.aws_iam_policy_document.this.json

  lifecycle {
    precondition {
      condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
      error_message = "KMS key deletion window must be between 7 and 30 days"
    }

    precondition {
      condition     = can(regex("^[a-z0-9-]+$", var.name))
      error_message = "Name must contain only lowercase letters, numbers, and hyphens"
    }

    postcondition {
      condition     = self.arn != ""
      error_message = "KMS key was created without an ARN"
    }
  }
}

data "aws_iam_policy_document" "this" {
  version = "2012-10-17"
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.admin_principals
    content {
      sid    = "AllowAdminPrincipals"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = statement.value
      }
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
      ]
      resources = ["*"]
    }
  }
}

resource "aws_kms_key_policy" "this" {
  key_id = aws_kms_key.this.id
  policy = data.aws_iam_policy_document.this.json
}

# Grant specific IAM roles access to use the key
resource "aws_kms_grant" "this" {
  for_each          = { for idx, principal in var.grant_principals : idx => principal }
  name              = "${var.name}-grant-${each.key}"
  key_id            = aws_kms_key.this.id
  grantee_principal = each.value
  operations        = var.grant_operations

  lifecycle {
    precondition {
      condition     = contains(["Encrypt", "Decrypt", "GenerateDataKey", "ReEncryptFrom", "ReEncryptTo"], each.value) == false
      error_message = "Grant operations must be valid KMS grant operations"
    }
  }
}
