terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Local state to start. Once the target AWS account is confirmed, migrate to
  # an S3 backend (create a state bucket + DynamoDB lock table, add a
  # `backend "s3" {}` block here, then run `terraform init -migrate-state`).
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "dare-dev-2026"
      ManagedBy = "terraform"
    }
  }
}

# ACM certificates for CloudFront must be requested in us-east-1, regardless
# of where everything else lives.
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = {
      Project   = "dare-dev-2026"
      ManagedBy = "terraform"
    }
  }
}
