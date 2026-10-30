variable "account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Supply the approved 12-digit project account ID."
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
  validation {
    condition     = var.region == "us-east-1"
    error_message = "Only the agreed us-east-1 region is supported by this baseline; review changes explicitly."
  }
}

variable "availability_zone" {
  type    = string
  default = "us-east-1c"
  validation {
    condition     = startswith(var.availability_zone, "us-east-1")
    error_message = "Use an availability zone in the approved region."
  }
}

variable "instance_type" {
  type = string
  validation {
    condition     = can(regex("^(t3\\.(micro|small|medium|large)|m7i-flex\\.large)$", var.instance_type))
    error_message = "Choose an explicitly reviewed x86 t3 size or m7i-flex.large. No size is assumed free or sufficient."
  }
}

variable "ami_id" {
  type = string
  validation {
    condition     = can(regex("^ami-[0-9a-f]{17}$", var.ami_id))
    error_message = "Supply a reviewed Ubuntu LTS x86_64 AMI ID for the region; verify Canonical ownership and SSM support."
  }
}

variable "root_volume_gib" {
  type    = number
  default = 30
  validation {
    condition     = var.root_volume_gib >= 20 && var.root_volume_gib <= 100 && floor(var.root_volume_gib) == var.root_volume_gib
    error_message = "Review an integer disk size between 20 and 100 GiB against allowances and capacity."
  }
}

variable "backup_bucket_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.backup_bucket_name))
    error_message = "Provide a unique lowercase backup bucket name (letters, digits, hyphens)."
  }
}

variable "notification_email" {
  type      = string
  sensitive = true
  validation {
    condition     = can(regex("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$", var.notification_email))
    error_message = "Supply a valid private email for budget and SNS notifications."
  }
}

variable "monthly_budget_usd" {
  type = number
  validation {
    condition     = var.monthly_budget_usd > 0 && var.monthly_budget_usd <= 1000
    error_message = "A positive, explicitly approved USD monthly alert threshold is required; it is not a spending cap."
  }
}

variable "teardown_after_utc" {
  type = string
  validation {
    condition     = can(formatdate("YYYY-MM-DD'T'hh:mm:ssZ", var.teardown_after_utc))
    error_message = "Provide a reviewed UTC teardown deadline in RFC3339 format. This tag is not an automatic scheduler."
  }
}

variable "existing_github_oidc_provider_arn" {
  type    = string
  default = null
  validation {
    condition     = var.existing_github_oidc_provider_arn == null ? true : can(regex("^arn:aws:iam::[0-9]{12}:oidc-provider/token.actions.githubusercontent.com$", var.existing_github_oidc_provider_arn))
    error_message = "Use the existing GitHub OIDC provider ARN, or null only after verifying no provider exists."
  }
}

variable "create_github_oidc_provider" {
  type    = bool
  default = false
}

variable "github_repository" {
  type    = string
  default = "Pavankp1010101010/Aws-gitOps-platform"
  validation {
    condition     = var.github_repository == "Pavankp1010101010/Aws-gitOps-platform"
    error_message = "OIDC trust is limited to the approved repository."
  }
}
