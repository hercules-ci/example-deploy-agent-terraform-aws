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

locals {
  public_key = "~/.ssh/id_rsa.pub"
  instance_type = "t3.medium"
  disk_size = 50 # in GiB
}

module "nixos" {
  source = "git::https://github.com/hercules-ci/terraform-hercules-ci.git//hercules_ci_agent_nixos?ref=c3c7e2155b7e872cab52460faa86a2fb0cd60375"
  target_host = aws_instance.machine.public_ip
  use_prebuilt = true
  configs = [abspath("${path.module}/configuration.nix")]
  cluster_join_token = "${file("${path.module}/cluster-join-token.key")}"
  binary_caches_json = "${file("${path.module}/binary-caches.json")}"
  NIX_PATH = "nixpkgs=${jsondecode(file("${path.module}/nix/sources.json"))["nixpkgs"]["url"]}"

  # This is not a great solution.
  # Also, run `ssh-add ~/.ssh/id_rsa`
  ssh_private_key_file = "~/.ssh/id_rsa"
  ssh_agent = true

  triggers = {
    machine_id = aws_instance.machine.id
    a = 1
  }
}

module "nixos_image_1909" {
  source = "git::https://github.com/hercules-ci/terraform-nixos.git//aws_image_nixos?ref=65fc5758a6660386a02ab32d9e7245cd9a521445"
  release = "20.03"
}

resource "aws_security_group" "ssh_and_egress" {
  ingress {
    # SSH for deployment
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ] # TODO: restrict
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key-${sha256(file(local.public_key))}"
  public_key = file(local.public_key)
}

resource "aws_instance" "machine" {
  ami           = module.nixos_image_1909.ami
  instance_type = local.instance_type
  security_groups = [ aws_security_group.ssh_and_egress.name ]
  key_name = aws_key_pair.deployer.key_name
  
  root_block_device {
    volume_size = local.disk_size # GiB
  }
}

output "public_dns" {
  value = aws_instance.machine.public_dns
}

################

resource "aws_s3_bucket" "terraform_state" {
  bucket_prefix = "tf-state"
  acl           = "private"

  versioning {
    enabled = true
  }

  tags = {
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

  tags = {
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

