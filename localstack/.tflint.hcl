plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.45.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"

  # Validate resources against actual AWS API
  deep_check = true
}

# config {
#   call_module_type = "all"
# }
