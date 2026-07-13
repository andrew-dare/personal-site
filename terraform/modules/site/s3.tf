resource "aws_s3_bucket" "site" {
  bucket = local.bucket_name

  # This bucket only ever holds build output the CD pipeline regenerates on
  # every deploy — nothing irreplaceable. Without force_destroy, Terraform
  # can't delete a non-empty bucket (BucketNotEmpty), which blocks exactly
  # the kind of domain/bucket-name change this module is built to support.
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# CloudFront reaches the bucket via Origin Access Control — the bucket itself
# stays private with no public website hosting or ACLs.
data "aws_iam_policy_document" "site_bucket" {
  statement {
    sid       = "AllowCloudFrontReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.site.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.site_bucket.json
}
