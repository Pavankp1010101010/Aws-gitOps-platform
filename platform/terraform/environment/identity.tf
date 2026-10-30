locals {
  github_repository_owner_id = "93963930"
  github_repository_id       = "1438499998"
  github_repository_subject  = "repo:${replace(var.github_repository, "/", "@${local.github_repository_owner_id}/")}@${local.github_repository_id}:ref:refs/heads/main"
}

resource "aws_iam_role" "host" {
  name = "${local.name}-host"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "host" {
  name = "${local.name}-host"
  role = aws_iam_role.host.name
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.host.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "host" {
  name = "project-registry-and-backup-access"
  role = aws_iam_role.host.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Effect   = "Allow"
        Action   = ["ecr:BatchCheckLayerAvailability", "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage"]
        Resource = aws_ecr_repository.application.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.backups.arn}/postgres/*"
      },
      {
        Effect    = "Allow"
        Action    = ["s3:ListBucket"]
        Resource  = aws_s3_bucket.backups.arn
        Condition = { StringLike = { "s3:prefix" = ["postgres/*"] } }
      }
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  count          = var.create_github_oidc_provider ? 1 : 0
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

resource "aws_iam_role" "image_publisher" {
  name = "${local.name}-image-publisher"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = local.github_repository_subject
        }
      }
    }]
  })
  lifecycle {
    precondition {
      condition     = var.create_github_oidc_provider != (var.existing_github_oidc_provider_arn != null)
      error_message = "Choose exactly one: explicitly create a verified-absent GitHub provider, or reference the existing shared provider without modifying it."
    }
    precondition {
      condition     = var.existing_github_oidc_provider_arn == null ? true : startswith(var.existing_github_oidc_provider_arn, "arn:aws:iam::${var.account_id}:")
      error_message = "The existing OIDC provider must belong to the approved project account."
    }
  }
}

resource "aws_iam_role_policy" "image_publisher" {
  name = "publish-project-images-only"
  role = aws_iam_role.image_publisher.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ecr:GetAuthorizationToken"], Resource = "*" },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability", "ecr:DescribeImages", "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart", "ecr:CompleteLayerUpload", "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.application.arn
      }
    ]
  })
}
