############################################
# IAM
############################################

resource "aws_iam_role" "lambda_role" {
  name = "serverless_website_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "serverless_lambda_policy"
  role = "${aws_iam_role.lambda_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
          "Effect": "Allow",
          "Action": "s3:*",
          "Resource": "*"
        }
    ]
}
EOF
}

############################################
# LAMBDA
############################################

resource "aws_lambda_function" "manifold_ian_api" {
  function_name = "${var.function_name}"
  role = "${aws_iam_role.lambda_role.arn}"
  handler = "${var.handler}"
  runtime = "${var.runtime}"

  # # fetch the artifact from bucket created earlier
  # s3_bucket = "${var.artifact_bucket}"
  # s3_key    = "v1.0.0/${var.artifact_zip_name}"

  source_code_hash = "${base64sha256(file("../lambda.zip"))}"
  filename      = "../lambda.zip"

  environment {
    variables = {
      data_bucket_name = "${var.data_bucket}"
    }
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.manifold_ian_api.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.imyjer_manifold_api.execution_arn}/*/*"
}

############################################
# API GATEWAY
############################################

# api gateway parent object
resource "aws_api_gateway_rest_api" "imyjer_manifold_api" {
  name = "Ian Manifold API Gateway"
  description = "Ian Manifold API Gateway"
}

# path resource
resource "aws_api_gateway_resource" "imyjer_manifold_gw_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.imyjer_manifold_api.id}"
  parent_id = "${aws_api_gateway_rest_api.imyjer_manifold_api.root_resource_id}"
  path_part = "${var.api_path_part}"
}

# POST method on path resource above ^^
resource "aws_api_gateway_method" "imyjer_manifold_api_method" {
  rest_api_id = "${aws_api_gateway_rest_api.imyjer_manifold_api.id}"
  resource_id = "${aws_api_gateway_resource.imyjer_manifold_gw_resource.id}"
  http_method = "POST"
  authorization = "NONE"
}

# integration with lambda
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = "${aws_api_gateway_rest_api.imyjer_manifold_api.id}"
  resource_id = "${aws_api_gateway_resource.imyjer_manifold_gw_resource.id}"
  http_method = "${aws_api_gateway_method.imyjer_manifold_api_method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.manifold_ian_api.invoke_arn}"
}

# deployment
resource "aws_api_gateway_deployment" "gw_deploy" {
  depends_on = [
    "aws_api_gateway_integration.lambda",
    "aws_api_gateway_method.imyjer_manifold_api_method"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.imyjer_manifold_api.id}"
  stage_name  = "prod"
}
