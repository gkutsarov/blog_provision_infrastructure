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

#GENERATE SSH KEY PAIR
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#OUTPUT PRIVATE KEY
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

#OUTPUT PUBLIC KEY
output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}

#IMPORT THE PUBLIC KEY TO AWS
resource "aws_key_pair" "ssh_key" {
  key_name   = "web-server-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
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

#CREATE SECURITY GROUP FOR SSH TRAFFIC TO THE EC2 INSTANCE
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Security group for SSH access"
}

#CREATE SECURITY GROUP FOR HTTP AND HTTPS TRAFFIC
resource "aws_security_group" "allow_http_https" {
  name        = "allow_http_https"
  description = "Security group for HTTP and HTTPS access"

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows traffic from any IP
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows traffic from any IP
  }

}

#CREATE SECURITY GROUP TO ALLOW OUTBOUND TRAFFIC
resource "aws_security_group" "allow_outbound" {
  name        = "allow_outbound"
  description = "Security group to allow outbound traffic"

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
  key_name               = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_outbound.id, aws_security_group.allow_http_https]
}

#S3 Bucket for Terraform Configuration
resource "aws_s3_bucket" "my-terraform-state-gk" {
  bucket = "my-terraform-state-gk"

  tags = {
    Name = "TerraformStateBucket"
  }
}

#Enable bucket versioning
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
