locals {
  name = "agtp-demo"
}

resource "aws_vpc" "project" {
  cidr_block           = "10.77.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.name}-vpc" }
}

resource "aws_internet_gateway" "project" {
  vpc_id = aws_vpc.project.id
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.77.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = false
  tags                    = { Name = "${local.name}-public" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.project.id
}

resource "aws_route" "internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.project.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "host" {
  name_prefix = "${local.name}-host-"
  description = "Private demo administration via outbound SSM only; no inbound rules"
  vpc_id      = aws_vpc.project.id
  ingress     = []
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.host.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound SSM, registry, DNS, NTP, and bootstrap dependencies"
}

resource "aws_instance" "host" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.host.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.host.name
  user_data = templatefile("${path.module}/../../bootstrap/cloud-config.yaml.tftpl", {
    bootstrap_script = base64encode(replace(file("${path.module}/../../bootstrap/bootstrap.sh"), "\r\n", "\n"))
    root_app         = filebase64("${path.module}/../../kubernetes/root-app.yaml")
  })
  monitoring                  = false
  user_data_replace_on_change = true
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  dynamic "credit_specification" {
    for_each = startswith(var.instance_type, "t3.") ? [1] : []
    content {
      cpu_credits = "standard"
    }
  }
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_gib
    encrypted             = true
    delete_on_termination = true
  }
  tags = {
    Name          = "${local.name}-k3s"
    TeardownAfter = var.teardown_after_utc
  }
  depends_on = [
    aws_route.internet,
    aws_route_table_association.public,
    aws_iam_role_policy_attachment.ssm,
    aws_budgets_budget.project
  ]
}

resource "aws_ecr_repository" "application" {
  name                 = "${local.name}-support-ticket"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = false
  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "application" {
  repository = aws_ecr_repository.application.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Expire only untagged images after seven days"
      selection    = { tagStatus = "untagged", countType = "sinceImagePushed", countUnit = "days", countNumber = 7 }
      action       = { type = "expire" }
    }]
  })
}

resource "aws_s3_bucket" "backups" {
  bucket        = var.backup_bucket_name
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "backups" {
  bucket                  = aws_s3_bucket.backups.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "backups" {
  bucket = aws_s3_bucket.backups.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyInsecureTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.backups.arn, "${aws_s3_bucket.backups.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket     = aws_s3_bucket.backups.id
  depends_on = [aws_s3_bucket_versioning.backups]
  rule {
    id     = "abort-incomplete-uploads-only"
    status = "Enabled"
    filter {
      prefix = ""
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  rule {
    id     = "expire-automated-postgres-backups"
    status = "Enabled"
    filter {
      prefix = "postgres/automated/"
    }
    expiration {
      days = 7
    }
    noncurrent_version_expiration {
      noncurrent_days = 1
    }
  }
}
