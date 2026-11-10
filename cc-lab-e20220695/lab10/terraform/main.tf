terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.67"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  bucket_name = "my-bucket-e20220695"
}

resource "aws_s3_bucket_ownership_controls" "my_bucket" {
  bucket = local.bucket_name
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket" {
  bucket = local.bucket_name

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "my_bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.my_bucket,
    aws_s3_bucket_public_access_block.my_bucket,
  ]

  bucket = local.bucket_name
  acl    = "public-read"
}

resource "aws_s3_object" "my_object" {
  bucket       = local.bucket_name
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}

data "aws_iam_policy_document" "allow_access" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:GetObject"]
    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "allow_access" {
  bucket = local.bucket_name
  policy = data.aws_iam_policy_document.allow_access.json
}

data "aws_iam_role" "LambdaRole" {
  name = "LabRole"
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "lambda.py"
  output_path = "lambda_function_payload.zip"
}

resource "aws_lambda_function" "LambdaFunction" {
  filename         = "lambda_function_payload.zip"
  function_name    = "LambdaFunction"
  role             = data.aws_iam_role.LambdaRole.arn
  handler          = "lambda.lambda_handler"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  runtime          = "python3.10"
}
resource "aws_lambda_function_url" "LambdaFunction" {
    function_name      = aws_lambda_function.LambdaFunction.function_name
    authorization_type = "NONE"
  }
  resource "aws_lambda_permission" "allow_function_url" {
    statement_id           = "AllowPublicFunctionUrl"
    action                 = "lambda:InvokeFunctionUrl"
    function_name          = aws_lambda_function.LambdaFunction.function_name
    principal              = "*"
    function_url_auth_type = "NONE"
  }
  resource "aws_lambda_permission" "allow_invoke" {
    statement_id  = "AllowPublicInvoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.LambdaFunction.function_name
    principal     = "*"
  }
  output "function_url" {
    value = aws_lambda_function_url.LambdaFunction.function_url
  }

resource "aws_security_group" "instance_sg" {
    name        = "allow-port-3000"
    description = "Allow incoming traffic on port 3000"
    ingress {
      from_port   = 3000
      to_port     = 3000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

data "aws_ssm_parameter" "al2023" {
    name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  }
  resource "aws_instance" "my_app" {
    ami             = data.aws_ssm_parameter.al2023.value
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.instance_sg.name]
    user_data = <<-EOF
      #!/bin/bash
      sudo yum -y update &&\
      sudo yum -y install git &&\
      sudo yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y &&\
      sudo yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1 &&\
      git clone https://github.com/Educative-Content/my-reactapp.git &&\
      cd my-reactapp &&\
      npm install &&\
      npm start
    EOF
    tags = {
      Name = "clab-app"
    }
  }
  output "public_ip" {
    value = aws_instance.my_app.public_ip
  }

