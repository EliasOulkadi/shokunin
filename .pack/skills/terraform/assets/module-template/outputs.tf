# outputs.tf — Module outputs

output "key_id" {
  description = "KMS key ID"
  value       = aws_kms_key.this.key_id
  sensitive   = false
}

output "key_arn" {
  description = "KMS key ARN"
  value       = aws_kms_key.this.arn
  sensitive   = true
}

output "key_alias_arn" {
  description = "KMS key alias ARN"
  value       = aws_kms_alias.this.arn
  sensitive   = true
}

output "key_alias_name" {
  description = "KMS key alias name"
  value       = aws_kms_alias.this.name
  sensitive   = false
}

# The key policy is returned for validation but marked sensitive
output "key_policy" {
  description = "KMS key resource policy"
  value       = data.aws_iam_policy_document.this.json
  sensitive   = true
}

# Precondition on consumers: ensure key rotation is enabled in non-dev
output "rotation_enabled" {
  description = "Whether key rotation is enabled"
  value       = aws_kms_key.this.enable_key_rotation

  precondition {
    condition     = var.enable_key_rotation || can(regex("^(dev|test)", var.name))
    error_message = "Key rotation must be enabled for non-development environments. Set enable_key_rotation = true."
  }
}
