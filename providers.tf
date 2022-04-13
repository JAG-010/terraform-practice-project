terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

// you can change your authentication system as per your needs
// https://registry.terraform.io/providers/hashicorp/aws/latest/docs
provider "aws" {
  region                  = "us-east-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "personal"
}