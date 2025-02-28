terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-g1-2403"
    key            = "ec2/statefile.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock-table"
    encrypt        = true
  }
}