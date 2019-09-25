# example-deploy-agent-terraform-aws
Example deployment of the Hercules CI Agent with Terraform to Amazon Web Services

It is designed to be deployed from a bastion host in the same region.
You are encouraged to copy and adapt this module to your conventions and requirements.

### Deployment

<!-- TODO refine these steps when frontend / docs are updated -->

1. Get a cluster join token from the [dashboard](https://hercules-ci.com/dashboard)
2. Create a binary caches file and save it as `binary-caches.json.key` by following roughly [this subsection](https://docs.hercules-ci.com/hercules-ci/getting-started/deploy/manual/#_3_configure_binary_caches)
3. Configure [AWS credentials for Terraform](https://www.terraform.io/docs/providers/aws/index.html)
4. Create the S3 bucket for the terraform state as hinted in `main.tf` comments
5. On a bastion host, run
```
$ ssh-add ~/.ssh/id_rsa
$ ./deploy
```
7. Securely backup the secrets

### Update

Consult the hercules-ci-agent changelog.
 - Pull changes from the public example into a private fork.
 - `./update` if necessary.
 - `./deploy`
