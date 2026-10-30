output "instance_id" {
  value = aws_instance.host.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.application.repository_url
}

output "backup_bucket_name" {
  value = aws_s3_bucket.backups.id
}

output "github_image_publisher_role_arn" {
  value = aws_iam_role.image_publisher.arn
}

output "host_alarm_topic_arn" {
  value = aws_sns_topic.host.arn
}
