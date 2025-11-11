# AWS Secrets Manager for storing API keys
resource "aws_secretsmanager_secret" "api_keys" {
  name        = var.secret_name
  description = "API keys for Airtable and OpenAI"

  recovery_window_in_days = 7

  tags = merge(var.tags, {
    Name = var.secret_name
  })
}

# Secret version - You need to manually update this with actual values
# or use AWS CLI/Console after creation
resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id

  # Placeholder values - MUST BE UPDATED after deployment
  secret_string = jsonencode({
    airtable_api_key    = "YOUR_AIRTABLE_API_KEY_HERE"
    airtable_base_id    = "YOUR_AIRTABLE_BASE_ID_HERE"
    airtable_table_name = "일상기록"
    openai_api_key      = "YOUR_OPENAI_API_KEY_HERE"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
