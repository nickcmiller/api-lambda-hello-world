terraform {
  backend "s3" {
    bucket = "terraform-state-bucket-api-lambda-hello-world"
    key    = "terraform.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}

provider "aws" {
  region = "us-west-2"
}

# Retrieve current AWS region
data "aws_region" "current" {}


# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "hello_world_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement: [
      {
        Action: "sts:AssumeRole",
        Effect: "Allow",
        Principal: {
          Service: "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWSLambdaBasicExecutionRole policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "hello_world" {
  filename         = "${path.module}/lambda/lambda_function.zip"
  function_name    = "hello_world_lambda"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  source_code_hash = filebase64sha256("${path.module}/lambda/lambda_function.zip")

  environment {
    variables = {
      LOGGING_LEVEL  = "INFO"  
      ALLOWED_ORIGIN = "*"
    }
  }
}
# # API Gateway Rest API
resource "aws_api_gateway_rest_api" "hello_world_api" {
  name = "hello_world_api"
}

# # API Gateway Resource
resource "aws_api_gateway_resource" "hello_world_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  parent_id   = aws_api_gateway_rest_api.hello_world_api.root_resource_id
  path_part   = "hello"
}

# # API Gateway Method
resource "aws_api_gateway_method" "hello_world_method" {
  rest_api_id   = aws_api_gateway_rest_api.hello_world_api.id
  resource_id   = aws_api_gateway_resource.hello_world_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "hello_world_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hello_world_api.id
  resource_id             = aws_api_gateway_resource.hello_world_resource.id
  http_method             = aws_api_gateway_method.hello_world_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.hello_world.arn}/invocations"
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway_lambda" {
  function_name = aws_lambda_function.hello_world.function_name
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hello_world_api.execution_arn}/*/*"
}

# # API Gateway Deployment
resource "aws_api_gateway_deployment" "hello_world_deployment" {
  rest_api_id = aws_api_gateway_rest_api.hello_world_api.id
  stage_name  = "dev"

  # Ensure deployment occurs after integration
  depends_on = [aws_api_gateway_integration.hello_world_integration]

  # Redeploy when API changes
  triggers = {
    redeployment = sha256(jsonencode(aws_api_gateway_rest_api.hello_world_api))
  }
}

# Output the API Gateway URL
output "api_url" {
  value = "${aws_api_gateway_deployment.hello_world_deployment.invoke_url}/hello"
}
