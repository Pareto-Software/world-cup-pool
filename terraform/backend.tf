terraform {
  backend "azurerm" {
    resource_group_name = "rg-football-tfstate"
    container_name      = "tfstate"
    key                 = "football.tfstate"
    # storage_account_name is supplied via backend.tfvars (gitignored)
    # Run: terraform init -backend-config=backend.tfvars
  }
}
