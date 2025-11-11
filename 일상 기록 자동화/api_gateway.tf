# HTTP API Gateway
resource "aws_apigatewayv2_api" "daily_log_api" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"
  description   = "API for daily log automation"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["POST", "OPTIONS"]
    allow_headers = ["content-type", "x-api-key"]
    max_age       = 300
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-api"
  })
}

# API Gateway Stage
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.daily_log_api.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-stage"
  })
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.project_name}-api-logs"
  })
}

# Lambda Integration
resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.daily_log_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Lambda integration for daily log processing"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.daily_log_processor.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

# API Route
resource "aws_apigatewayv2_route" "daily_log" {
  api_id    = aws_apigatewayv2_api.daily_log_api.id
  route_key = "POST /daily-log"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}
