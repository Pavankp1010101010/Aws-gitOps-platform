mock_provider "aws" {}

variables {
  account_id                        = "123456789012"
  instance_type                     = "t3.medium"
  ami_id                            = "ami-00000000000000000"
  backup_bucket_name                = "synthetic-project-backups-test"
  notification_email                = "synthetic@example.invalid"
  monthly_budget_usd                = 10
  teardown_after_utc                = "2099-01-01T00:00:00Z"
  create_github_oidc_provider       = false
  existing_github_oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
}

run "restricted_foundation_plan" {
  command = plan
  assert {
    condition     = length(aws_security_group.host.ingress) == 0
    error_message = "No public application, admin, SSH, API, or database ingress is allowed."
  }
  assert {
    condition     = aws_instance.host.metadata_options[0].http_tokens == "required" && aws_instance.host.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "IMDSv2 and hop limit 1 are required."
  }
  assert {
    condition     = aws_instance.host.user_data_replace_on_change && strcontains(aws_instance.host.user_data, "agtp-stage05-bootstrap.sh")
    error_message = "Stage 05 bootstrap must be pinned in instance user data and rerun on host replacement."
  }
  assert {
    condition     = aws_instance.host.root_block_device[0].encrypted && aws_instance.host.root_block_device[0].volume_type == "gp3"
    error_message = "The project disk must use encrypted gp3."
  }
  assert {
    condition     = aws_instance.host.credit_specification[0].cpu_credits == "standard"
    error_message = "Do not enable potentially billable unlimited CPU credits."
  }
  assert {
    condition     = aws_ecr_repository.application.image_tag_mutability == "IMMUTABLE" && !aws_ecr_repository.application.force_delete
    error_message = "Registry tags must be immutable and retained on nonempty deletion."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.backups.block_public_acls && aws_s3_bucket_public_access_block.backups.block_public_policy && aws_s3_bucket_public_access_block.backups.ignore_public_acls && aws_s3_bucket_public_access_block.backups.restrict_public_buckets
    error_message = "Backups must block all public access."
  }
  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "A shared OIDC provider must not be recreated by default."
  }
  assert {
    condition     = jsondecode(aws_iam_role.image_publisher.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:sub"] == "repo:Pavankp1010101010/Aws-gitOps-platform:ref:refs/heads/main"
    error_message = "Image publisher trust must be exact repository/main, not pull requests."
  }
}

run "sns_policy_uses_supported_action_prefix" {
  command = apply
  override_resource {
    target = aws_sns_topic.host
    values = {
      arn = "arn:aws:sns:us-east-1:123456789012:synthetic-project-topic"
    }
  }
  assert {
    condition = sort(jsondecode(aws_sns_topic_policy.host.policy).Statement[0].Action) == sort([
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
    ])
    error_message = "SNS topic administration must use explicit supported actions rather than a wildcard."
  }
  assert {
    condition     = jsondecode(aws_sns_topic_policy.host.policy).Statement[1].Action == "SNS:Publish"
    error_message = "CloudWatch must be granted the explicit SNS:Publish action."
  }
}

run "m7i_flex_host_omits_burstable_credit_settings" {
  command = plan
  variables {
    instance_type = "m7i-flex.large"
  }
  assert {
    condition     = aws_instance.host.instance_type == "m7i-flex.large" && length(aws_instance.host.credit_specification) == 0
    error_message = "The non-burstable m7i-flex host must not receive T-series CPU-credit settings."
  }
}

run "reject_ambiguous_oidc_ownership" {
  command = plan
  variables {
    create_github_oidc_provider = true
  }
  expect_failures = [aws_iam_role.image_publisher]
}

run "reject_wrong_account_oidc" {
  command = plan
  variables {
    existing_github_oidc_provider_arn = "arn:aws:iam::999999999999:oidc-provider/token.actions.githubusercontent.com"
  }
  expect_failures = [aws_iam_role.image_publisher]
}

run "reject_unapproved_region" {
  command = plan
  variables {
    region = "ap-south-1"
  }
  expect_failures = [var.region]
}
