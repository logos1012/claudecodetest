output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.main.arn
}

output "folder_key" {
  description = "Key of the created folder object"
  value       = aws_s3_object.test_folder.key
}
