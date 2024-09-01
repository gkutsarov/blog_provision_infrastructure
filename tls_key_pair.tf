#GENERATE SSH KEY PAIR
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#OUTPUT PRIVATE AND PUBLIC KEYS
output "private_key" {
  value     = tls_private_key.ssh_key.private_key_pem
  sensitive = true
}

output "public_key" {
  value = tls_private_key.ssh_key.public_key_openssh
}

#IMPORT THE PUBLIC KEY TO AWS
resource "aws_key_pair" "ssh_key" {
  key_name   = "web-server-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}