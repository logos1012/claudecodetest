output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "${aws_apigatewayv2_api.daily_log_api.api_endpoint}/${var.environment}/daily-log"
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.daily_log_api.id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.daily_log_processor.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.daily_log_processor.arn
}

output "secret_name" {
  description = "Secrets Manager secret name"
  value       = aws_secretsmanager_secret.api_keys.name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN"
  value       = aws_secretsmanager_secret.api_keys.arn
}

output "cloudwatch_log_group_lambda" {
  description = "CloudWatch Log Group for Lambda"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "cloudwatch_log_group_api_gateway" {
  description = "CloudWatch Log Group for API Gateway"
  value       = aws_cloudwatch_log_group.api_gateway_logs.name
}
