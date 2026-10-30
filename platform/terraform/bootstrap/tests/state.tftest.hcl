mock_provider "aws" {}

variables {
  account_id        = "123456789012"
  state_bucket_name = "synthetic-project-state-test"
}

run "private_encrypted_versioned_state" {
  command = plan
  assert {
    condition     = aws_s3_bucket.state.force_destroy == false
    error_message = "State storage must not force-delete data."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls && aws_s3_bucket_public_access_block.state.block_public_policy && aws_s3_bucket_public_access_block.state.ignore_public_acls && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    error_message = "All public-access protections must be enabled."
  }
  assert {
    condition     = one(aws_s3_bucket_versioning.state.versioning_configuration).status == "Enabled"
    error_message = "State versions must be retained."
  }
  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.state.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "State must be encrypted."
  }
}
