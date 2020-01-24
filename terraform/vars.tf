provider "aws" {
  profile    = "${var.profile}"
  region     = "${var.region}"
}

variable "region" {
  default = "us-east-1"
}

variable "profile" {
  default = "default"
}

## S3 Buckets ##
variable "data_bucket" {
  default = "imyjer-manifold-data"
}

variable "artifact_bucket" {
  description = "bucket for lambda python zip"
  default     = "imyjer-manifold-artifact"
}

## Lambda ## 
variable "artifact_zip_name" {
  description = "name of the zip file"
  default     = "lambda.zip"
}

variable "function_name" {
  default = "manifold-ian-lambda"
}

variable "handler" {
  default = "lambda_to_s3_nopandas.lambda_handler"
}

variable "runtime" {
  default = "python3.7"
}

## API ##
variable "api_name" {
  default = "manifold-ian-api"
}

variable "api_path_part" {
  default = "v1.0"
}
