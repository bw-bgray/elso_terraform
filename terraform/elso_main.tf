# main.tf - Enterprise Landing Zone for Azure with Compliance, Monitoring & Security

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id_prod
}

provider "azurerm" {
  alias           = "connectivity"
  features        {}
  subscription_id = var.subscription_id_connectivity
}

provider "azurerm" {
  alias           = "nonprod"
  features        {}
  subscription_id = var.subscription_id_nonprod
}

# 1️⃣ Management Groups
resource "azurerm_management_group" "elso" {
  name = "ELSO"
}

resource "azurerm_management_group" "platform" {
  name                       = "Platform"
  parent_management_group_id = azurerm_management_group.elso.id
}

resource "azurerm_management_group" "landing_zones" {
  name                       = "Landing-Zones"
  parent_management_group_id = azurerm_management_group.elso.id
}

resource "azurerm_management_group" "prod" {
  name                       = "Prod"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "nonprod" {
  name                       = "NonProd"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

# 2️⃣ Networking
resource "azurerm_virtual_network" "isolated_vnet_prod" {
  name                = "isolated-vnet-prod"
  location            = var.location
  resource_group_name = "rg-prod"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network" "isolated_vnet_nonprod" {
  name                = "isolated-vnet-nonprod"
  location            = var.location
  resource_group_name = "rg-nonprod"
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_virtual_network" "avd_vnet" {
  provider            = azurerm.connectivity
  name                = "avd-vnet"
  location            = var.location
  resource_group_name = "rg-connectivity"
  address_space       = ["10.20.0.0/16"]
}

# Networking Peering
resource "azurerm_virtual_network_peering" "avd_to_prod" {
  name                         = "avd-to-prod"
  resource_group_name          = "rg-connectivity"
  virtual_network_name         = azurerm_virtual_network.avd_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.isolated_vnet_prod.id
}

resource "azurerm_virtual_network_peering" "avd_to_nonprod" {
  name                         = "avd-to-nonprod"
  resource_group_name          = "rg-connectivity"
  virtual_network_name         = azurerm_virtual_network.avd_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.isolated_vnet_nonprod.id
}

# 3️⃣ Azure Virtual Desktop (AVD)
resource "azurerm_virtual_desktop_host_pool" "avd_hostpool" {
  provider            = azurerm.connectivity
  name                = "avd-hostpool"
  resource_group_name = "rg-connectivity"
  location            = var.location
  type                = "Pooled"
  load_balancer_type  = "BreadthFirst"
}

resource "azurerm_virtual_desktop_workspace" "avd_workspace" {
  provider            = azurerm.connectivity
  name                = "avd-workspace"
  resource_group_name = "rg-connectivity"
  location            = var.location
}

# 4️⃣ HIPAA/HITRUST Compliance
resource "azurerm_policy_definition" "hipaa_policy" {
  name         = "hipaa-compliance-policy"
  policy_type  = "BuiltIn"
  mode         = "All"
  display_name = "HIPAA Compliance Policy"
  policy_rule  = file("hipaa_policy.json")
}

resource "azurerm_policy_assignment" "hipaa_assignment" {
  name                 = "hipaa-hitrust-compliance"
  scope                = azurerm_management_group.prod.id
  policy_definition_id = azurerm_policy_definition.hipaa_policy.id
  enforcement_mode     = "Default"
}

# 5️⃣ Monitoring & Log Retention
resource "azurerm_log_analytics_workspace" "log_workspace" {
  name                = "log-analytics-workspace"
  location            = var.location
  resource_group_name = "rg-management"
  retention_in_days   = var.log_retention_days
}

resource "azurerm_monitor_diagnostic_setting" "monitor_diag" {
  name                           = "diagnostic-settings"
  target_resource_id             = azurerm_virtual_network.isolated_vnet_prod.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log_workspace.id

  metric {
    category = "AllMetrics"
  }

  enabled_log {
    category = "AuditLogs"
  }
}

# 6️⃣ Alerts & Security Monitoring
resource "azurerm_monitor_action_group" "email_alerts" {
  name                = "email-alerts"
  resource_group_name = "rg-management"
  short_name          = "alerts"

  email_receiver {
    name          = "SecurityTeam"
    email_address = "security@example.com"
  }
}

resource "azurerm_monitor_metric_alert" "cpu_alert" {
  name                = "cpu-usage-alert"
  resource_group_name = "rg-management"
  scopes             = [azurerm_virtual_machine.web_vm.id]
  severity          = 2

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.email_alerts.id
  }
}

# 7️⃣ Log Retention Policy
resource "azurerm_storage_account" "log_storage" {
  name                     = "logstorageaccount"
  resource_group_name      = "rg-management"
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_log_profile" "log_profile" {
  name = "log-retention-policy"

  categories = ["Action", "Write", "Delete"]
  locations  = ["global"]

  storage_account_id = azurerm_storage_account.log_storage.id
  retention_policy {
    enabled = true
    days    = var.log_retention_days
  }
}
