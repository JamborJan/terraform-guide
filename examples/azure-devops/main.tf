
# export AZDO_PERSONAL_ACCESS_TOKEN="2xrxarqlrfgq7c26w3glxqolyzlygqirvmcmbw26koacbgcz63wq"
# export AZDO_ORG_SERVICE_URL=https://xwr.visualstudio.com/


terraform {
  required_providers {
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">=0.2.2"
    }
  }
}

resource "azuredevops_project" "project" {
  name          = "Project Name"
  description   = "Project Description"
}