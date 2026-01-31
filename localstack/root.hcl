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

  before_hook "tflint" {
    commands     = ["apply", "plan", "validate"]
    execute      = ["sh", "-c", "echo '=== Running TFLint ===' && tflint --minimum-failure-severity=warning"]
    run_on_error = false
    # execute = ["tflint"]
  }
}

locals {
  tags = merge(local.vars.tags, {
    provision_path = "${local.vars.repo_path}/${path_relative_to_include()}"
  })

  vars = yamldecode(file("vars.yaml"))
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "test-${local.vars.account_id}-terraform-state"
    key            = "aws/localstack/${path_relative_to_include()}/terraform.tfstate"
    region         = local.vars.default_region
    dynamodb_table = "terraform-locks"

    # This is required by localstack
    force_path_style = true

    s3_bucket_tags      = local.tags
    dynamodb_table_tags = local.tags
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
