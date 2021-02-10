# Notejam Infrastructure

## Local development
1. Set environment variables (e.g. with `direnv`)
  - `ARM_TENANT_ID` - Tenant ID
  - `ARM_SUBSCRIPTION_ID` - Subscription ID
2. Change into environment dir (e.g. `environments/prod`)
3. Execute plan with `terraform plan`
4. Deploy with `terraform apply`

## After first deployment
- Run scripts/post-deployment.sh for things that aren't achievable with Terraform currently from an environment folder (e.g. `environments/prod`)

## Create a new environment
1. Copy an existing environment (e.g. `environments/prod`) to a new folder (e.g. `environments/integration`)
2. Replace env variables for deployment if needed (see **Local development**, step 1)
3. Set / replace values in the main.tf for noteja, module file as needed

## Todos:
- Create Blob Store / Storage Account to use as remote state backend (see [azurerm](https://www.terraform.io/docs/backends/types/azurerm.html))