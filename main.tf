# Deploy, uncomment, update bucket field, nix-shell --run 'terraform init'
#
# terraform {
#   backend "s3" {
#     bucket         = "tf-stateXXXXXXXXXXXXXXXXXXXXXXXXXX"
#     region         = "eu-central-1"
#     key            = "hercules-ci-agents.tf"
#     encrypt        = "true"
#     dynamodb_table = "tf-state-lock"
#     # configure credentials here and in provider below
#   }
# }

provider "aws" {
  region = "eu-central-1"
  # configure credentials here and in s3 backend above
}

module "agent-1" {
  source = "git::https://github.com/hercules-ci/terraform-hercules-ci.git//hercules_ci_agent_aws?ref=046779cf55028e3f0e1541cb422de04e6ecb94a1"
  use_prebuilt = true
  cluster_join_token = "${file("${path.module}/cluster-join-token.key")}"
  binary_caches_json = "${file("${path.module}/binary-caches.json")}"

  # This is not a great solution.
  # Also, run `ssh-add ~/.ssh/id_rsa`
  public_key = "${file("~/.ssh/id_rsa.pub")}"

  configs = [
    "${path.module}/extra-configuration.nix",
  ]
}

output "public_dns" {
  value = "${module.agent-1.public_dns}"
}

################

resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "tf-state"
  acl           = "private"

  versioning {
    enabled = true
  }

  tags {
    Name = "Terraform State"
  }
}

resource "aws_dynamodb_table" "terraform_state" {
  name           = "tf-state-lock"
  hash_key       = "LockID"
  read_capacity  = 10
  write_capacity = 10

  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    Name = "Terraform Lock Table"
  }
}

output "terraform_bucket" {
  description = "The name of the bucket where terraform state is stored."
  value       = "${aws_s3_bucket.terraform_state.id}"
}

output "terraform_dynamodb_table" {
  description = "The name of the dynamodb table that is used for locking."
  value       = "${aws_dynamodb_table.terraform_state.name}"
}

