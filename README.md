# Terragrunt issue reprodution

This repository is meant to be used as a quick validation for a Terragrunt bug I
am troubleshooting where error logs are not outputting in new versions.

## Reproduction

Here is the relevant infor for reproducing this issue locally. I am using
localstack here but it should be reproducible against AWS. I am using an
upstream public module in the example but it should be possible to trigger the
issue by changing any terragrunt.hcl config to use a non-existant local
variable.

As best as I can tell the behavior changed in 0.73.0, as it works in 0.72.9.

Below is the structure and specific configs used to recreate the test.

```bash
tree
.
└── localstack
    ├── root.hcl
    └── us-west-2
        └── s3
            └── test
                └── terragrunt.hcl
```

### root.hcl

```hcl
terraform {
  extra_arguments "defaults" {
    commands  = ["init"]
    arguments = ["-no-color"]
  }

  extra_arguments "profile" {
    commands  = ["apply", "destroy", "plan"]
    arguments = []
    env_vars = {
      AWS_PROFILE = "localstack"
    }
  }
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "test-terraform-state"
    key            = "aws/localstack/${path_relative_to_include()}/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"

    # This is required by localstack
    force_path_style = true
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
```

### terragrunt.hcl

Intentionally set the bucket to a local that doesn't exist.

```hcl
terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=5.7.0"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  bucket = "terragrunt-test"

  tags = {
    Name = local.bucket
  }

  vars = yamldecode(file(find_in_parent_folders("vars.yaml")))
}

inputs = {
  acl                  = "private"
  attach_policy        = true
  attach_public_policy = false

  # Trigger the issue by intentionally referencing a local variable that doesn't exist
  bucket               = local.bar

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

  tags = local.tags

  versioning = {
    enabled = true
  }
}
```

### Using Terragrunt v0.66.7

Error is shown as expected.

```hcl
terragrunt plan
ERRO[0000] Error: Unsupported attribute

ERRO[0000]   on /Users/joshuareichardt/hack/terragrunt-experiment/localstack/us-west-2/s3/test/terragrunt.hcl line 23:
ERRO[0000]   23:   bucket               = local.bar
ERRO[0000]
ERRO[0000] This object does not have an attribute named "bar".

ERRO[0000] /Users/joshuareichardt/hack/terragrunt-experiment/localstack/us-west-2/s3/test/terragrunt.hcl:23,31-35: Unsupported attribute; This object does not have an attribute named "bar".
ERRO[0000] Unable to determine underlying exit code, so Terragrunt will exit with error code 1
```

Using Terragrunt v0.73+

```bash
terragrunt plan
(no output)
```

Also tried with various different debug levels

```bash
terragrunt plan --log-level debug
(no output)
```
