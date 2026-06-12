data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# ── Resource group ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-football"
  location = var.location
}

# ── Storage account for SQLite persistence (/pb_data) ────────────────────────
# App Service mounts Azure Files with nobrl (no byte-range locking),
# which allows SQLite to work correctly with a single replica.

resource "azurerm_storage_account" "data" {
  name                     = "stfbdata${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "pb_data" {
  name               = "pb-data"
  storage_account_id = azurerm_storage_account.data.id
  quota              = 5
}

# ── App Service ───────────────────────────────────────────────────────────────

resource "azurerm_service_plan" "main" {
  name                = "asp-football"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-football-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  https_only          = true

  site_config {
    health_check_path                 = "/api/health"
    health_check_eviction_time_in_min = 2

    application_stack {
      docker_image_name        = "pareto-software/world-cup-pool:${var.image_tag}"
      docker_registry_url      = "https://ghcr.io"
      docker_registry_username = "pareto-software"
      docker_registry_password = var.ghcr_token
    }
  }

  app_settings = {
    WEBSITES_PORT        = "8090"
    WMP_DEV              = "0"
    RESULTS_SOURCE       = var.results_source
    PB_ADMIN_EMAIL       = var.pb_admin_email
    PB_ADMIN_PASSWORD    = var.pb_admin_password
    GOOGLE_CLIENT_ID     = var.google_client_id
    GOOGLE_CLIENT_SECRET = var.google_client_secret
    ODDS_API_KEY         = var.odds_api_key
  }

  storage_account {
    name         = "pb-data"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.data.name
    share_name   = azurerm_storage_share.pb_data.name
    access_key   = azurerm_storage_account.data.primary_access_key
    mount_path   = "/pb_data"
  }
}

# ── Custom domain + managed TLS ──────────────────────────────────────────────

resource "azurerm_app_service_custom_hostname_binding" "main" {
  hostname            = "fudis.paretosoftware.fi"
  app_service_name    = azurerm_linux_web_app.main.name
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_app_service_managed_certificate" "main" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
}

resource "azurerm_app_service_certificate_binding" "main" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
  certificate_id      = azurerm_app_service_managed_certificate.main.id
  ssl_state           = "SniEnabled"
}

# Service principal for GitHub Actions is created manually — see outputs.tf for the command.
