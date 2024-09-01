terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

#GET UBUNTU ID
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical's AWS account ID
}

output "ubuntu_ami_id" {
  value = data.aws_ami.ubuntu.id
}

#CREATE SECURITY GROUP FOR EC2 INSTANCE
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Security group for SSH access"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["77.70.78.206/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" #Allow all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

}

#CREATE EC2 INSTANCE
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}

#S3 Bucket for Terraform Configuration
#Create S3 Bucket
resource "aws_s3_bucket" "my-terraform-state-gk" {
  bucket = "my-terraform-state-gk"

  tags = {
    Name = "TerraformStateBucket"
  }
}

resource "aws_s3_bucket_versioning" "my-terraform-state-gk" {
  bucket = aws_s3_bucket.my-terraform-state-gk.bucket

  versioning_configuration {
    status = "Enabled"
  }
}
#Block Public Access to the bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.my-terraform-state-gk.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#IAM Policy to allow access to the Terraform state S3 bucket
resource "aws_iam_policy" "terraform_state_policy" {
  name        = "TerraformStatePolicy"
  description = "Policy to allow access to the Terraform state S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::my-terraform-state-gk",
          "arn:aws:s3:::my-terraform-state-gk/*"
        ]
      }
    ]
  })
}

#Create IAM user to manage the S3 bucket
resource "aws_iam_user" "user_to_manage_tf_state" {
  name = "user_to_manage_tf_state"
}

#Attach IAM Policy to the above created user.

resource "aws_iam_user_policy_attachment" "attach_policy_to_iamadmin" {
  user       = "user_to_manage_tf_state"
  policy_arn = aws_iam_policy.terraform_state_policy.arn
}
