# variables.tf — Module input variables with validation

variable "name" {
  description = "Name prefix for all resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,62}$", var.name))
    error_message = "Name must be 3-63 chars, start with lowercase letter, contain only lowercase letters, numbers, and hyphens."
  }
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "Managed by Terraform"

  validation {
    condition     = length(var.description) <= 255
    error_message = "Description must be 255 characters or fewer."
  }
}

variable "deletion_window_in_days" {
  description = "Waiting period before KMS key deletion"
  type        = number
  default     = 30

  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "Deletion window must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  description = "Enable automatic annual key rotation"
  type        = bool
  default     = true
}

variable "admin_principals" {
  description = "IAM ARNs with administrative permissions on the key"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.admin_principals : can(regex("^(arn:aws:iam::\\d{12}:role/|arn:aws:iam::\\d{12}:user/)", arn))
    ])
    error_message = "Each admin principal must be a valid IAM role or user ARN."
  }
}

variable "grant_principals" {
  description = "IAM principals to grant KMS usage permissions"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.grant_principals : can(regex("^arn:aws:iam::", arn))
    ])
    error_message = "Each grant principal must be a valid IAM ARN."
  }
}

variable "grant_operations" {
  description = "KMS operations to grant"
  type        = list(string)
  default     = ["Encrypt", "Decrypt", "GenerateDataKey"]

  validation {
    condition = alltrue([
      for op in var.grant_operations : contains([
        "Decrypt", "Encrypt", "GenerateDataKey", "GenerateDataKeyWithoutPlaintext",
        "ReEncryptFrom", "ReEncryptTo", "RetireGrant", "Sign", "Verify",
        "CreateGrant", "DescribeKey",
      ], op)
    ])
    error_message = "Each operation must be a valid KMS grant operation."
  }
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for k, v in var.tags : can(regex("^[a-zA-Z0-9 _\\.:/+=@-]{1,128}$", k)) && can(regex("^[a-zA-Z0-9 _\\.:/+=@-]{0,256}$", v))
    ])
    error_message = "Tag keys (128 chars) and values (256 chars) must contain only valid characters."
  }
}
