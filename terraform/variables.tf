variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  default     = "northeurope"
  description = "Azure region for all resources"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "Docker image tag to deploy (e.g. '1.3.5' or 'latest')"
}

variable "pb_admin_email" {
  type        = string
  sensitive   = true
  description = "PocketBase bootstrap admin email"
}

variable "pb_admin_password" {
  type        = string
  sensitive   = true
  description = "PocketBase bootstrap admin password"
}

variable "google_client_id" {
  type        = string
  default     = ""
  description = "Google OAuth client ID (leave empty to disable)"
}

variable "google_client_secret" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Google OAuth client secret"
}

variable "odds_api_key" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The Odds API key (leave empty to use FIFA-ranking estimates)"
}

variable "ghcr_token" {
  type        = string
  sensitive   = true
  description = "GitHub PAT with read:packages scope for pulling from GHCR"
}

variable "results_source" {
  type        = string
  default     = "auto"
  description = "Result source: auto | openfootball | apifootball"
}
