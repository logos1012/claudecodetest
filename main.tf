terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = "claudecode-test-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "ClaudeCode Test Bucket"
    Environment = "Development"
  }
}

# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Create folder object 'test10121012/'
resource "aws_s3_object" "test_folder" {
  bucket  = aws_s3_bucket.main.id
  key     = "test10121012/"
  content = ""

  tags = {
    Name = "Test folder"
  }
}
