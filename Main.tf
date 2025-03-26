provider "azurerm" {
  features {}
}

variable "resource_group" {
  default = "testrg1"
}

variable "container_app" {
  default = "testapp1"
}

variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}
variable "subscription_id" {}

provider "null" {}

resource "null_resource" "deactivate_old_revisions" {
  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal -u ${var.client_id} -p ${var.client_secret} --tenant ${var.tenant_id}

      REVISIONS_LIST=$(az containerapp revision list --resource-group "${var.resource_group}" --name "${var.container_app}" --all \
        --query "[?properties.trafficWeight==\`0.0\` && properties.active==\`true\`].[name]" -o tsv || echo "")

      if [ -z "$REVISIONS_LIST" ]; then
        echo "No active revisions with 0% traffic found."
      else
        for REVISION in $REVISIONS_LIST; do
          echo "Deactivating revision: $REVISION"
          az containerapp revision deactivate --resource-group "${var.resource_group}" --name "${var.container_app}" --revision "$REVISION"
        done
      fi
    EOT
  }
}
