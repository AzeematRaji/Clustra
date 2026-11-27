locals {
  common_tags = {
    project      = "clustra"
    environment  = "shared"
    region       = "canadacentral"
    "managed-by" = "terraform"
    owner        = "azeematraji"
  }
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "tfstate" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  tags                            = local.common_tags

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  for_each             = toset(var.allowed_principal_ids)
  scope                = azurerm_storage_container.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value
}