# terraform.tfvars - Secure Variables Configuration

admin_username         = "azureuser"
admin_password         = "SuperSecureP@ssw0rd!" # Store in Azure Key Vault instead of plaintext!
subscription_id_connectivity = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
subscription_id_prod   = "YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"
subscription_id_nonprod = "ZZZZZZZZ-ZZZZ-ZZZZ-ZZZZ-ZZZZZZZZZZZZ"

log_retention_days     = 365
