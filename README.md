# S3 Terraform Configuration

This Terraform configuration creates an S3 bucket with a folder object named `test10121012/`.

## Resources Created

- **AWS S3 Bucket**: A bucket with a randomly generated unique name
- **S3 Folder Object**: A folder named `test10121012/` inside the bucket

## Prerequisites

- Terraform installed (version compatible with AWS provider ~> 5.0)
- AWS credentials configured (via AWS CLI, environment variables, or IAM role)

## Usage

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the planned changes:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. To destroy the resources:
   ```bash
   terraform destroy
   ```

## Outputs

- `bucket_name`: The name of the created S3 bucket
- `bucket_arn`: The ARN of the S3 bucket
- `folder_key`: The key of the created folder object (`test10121012/`)
