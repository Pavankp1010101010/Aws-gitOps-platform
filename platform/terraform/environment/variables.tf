variable "account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Supply the configured 12-digit AWS account ID."
  }
}

variable "project_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,31}$", var.project_name))
    error_message = "Use a lowercase project prefix (3-32 letters, digits, or hyphens) beginning with a letter."
  }
}

variable "region" {
  type = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region)) && !startswith(var.region, "cn-")
    error_message = "This baseline supports standard AWS commercial regions, not China, GovCloud, or isolated partitions."
  }
}

variable "availability_zone" {
  type = string
  validation {
    condition     = can(regex("^${var.region}[a-z]$", var.availability_zone))
    error_message = "Choose an availability zone in the configured region."
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
    error_message = "Supply a valid private email for SNS host notifications."
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
  type = string
  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "Use the GitHub owner/repository slug without a URL."
  }
}

variable "github_repository_owner_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_owner_id))
    error_message = "Supply the numeric GitHub owner ID for the configured repository."
  }
}

variable "github_repository_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]+$", var.github_repository_id))
    error_message = "Supply the numeric GitHub repository ID for the configured repository."
  }
}
