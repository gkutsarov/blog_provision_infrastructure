terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    hcp = {
      source = "hashicorp/hcp"
      version = "~> 0.95.0"
    }
  }
}

#LOGIN TO HCP Vault Cloud to fetch the AWS credentials
data "hcp_vault_secrets_app" "aws_credentials" {
  app_name = "aws-credentials"
}

output "secrets" {
  value = data.hcp_vault_secrets_app.aws_credentials.secrets
  sensitive = true
}

provider "aws" {
  region     = "us-west-2"
}

#CREATE EC2 INSTANCE
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

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  /*security_groups             = [aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
  }*/
}

#S3 Bucket for Terraform Configuration
#Create S3 Bucket
resource "aws_s3_bucket" "my-terraform-state-gk" {
  bucket = "my-terraform-state-gk"
   
  tags = {
    Name = "TerraformStateBucket"
  }
}

#SET BUCKET ACL
resource "aws_s3_bucket_acl" "my-tf-state-bucket-ACL" {
  bucket = aws_s3_bucket.my-terraform-state-gk.id
  acl = "private"
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

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

#IAM Policy to allow access to the Terraform state S3 bucket
resource "aws_iam_policy" "terraform_state_policy" {
  name = "TerraformStatePolicy"
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

#Attach IAM Policy to iamadmin user

resource "aws_iam_user_policy_attachment" "attach_policy_to_iamadmin" {
  user = "iamadmin"
  policy_arn = aws_iam_policy.terraform_state_policy.arn
}
