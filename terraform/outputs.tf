output "app_url" {
  value       = "https://${azurerm_app_service_custom_hostname_binding.main.hostname}"
  description = "Public URL of the deployed app — set this as PUBLIC_APP_URL"
}

output "github_actions_sp_command" {
  value = <<-EOT
    Run this once to create the GitHub Actions service principal:

    az ad sp create-for-rbac \
      --name sp-football-gha \
      --role Contributor \
      --scopes /subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/rg-football \
      --sdk-auth \
    | gh secret set AZURE_CREDENTIALS --repo Pareto-Software/world-cup-pool
  EOT
}
