terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=5.7.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  bucket = "terragrunt-test"
}

inputs = {
  acl                  = "private"
  attach_policy        = true
  attach_public_policy = false

  # We are intentionally breaking terraform here by referencing a local that doesn't exist
  bucket = local.bucket

  # Passing an invalid data types does not break the same way and an error is displayed during terraform plan/apply
  # bucket = 123

  lifecycle_rule = [{
    abort_incomplete_multipart_upload_days = 7
    id                                     = "test"
    enabled                                = true

    expiration = {
      days = 7
    }

    noncurrent_version_expiration = {
      noncurrent_days = 70
    }
  }]

  restrict_public_buckets = false

  versioning = {
    enabled = true
  }
}
