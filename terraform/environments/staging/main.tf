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

  # Local state to start. Consider migrating to an S3 backend so state isn't
  # only on one machine — see ../../README.md.
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = "dare-dev-2026"
      Environment = "staging"
      ManagedBy   = "terraform"
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
      Project     = "dare-dev-2026"
      Environment = "staging"
      ManagedBy   = "terraform"
    }
  }
}
