terraform {
  backend "s3" {
    #I use env variables for access key and secret key
    bucket = "my-terraform-state-gk"
    key    = "terraform.tfstate"
    region = "us-west-2"
    #ENABLE LOCKS for terraform in AWS in DYNAMODB
    dynamodb_table = "terrafom-locks"
    encrypt        = true
}
}
