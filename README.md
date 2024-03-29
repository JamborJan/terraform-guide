# Terraform quick start guide

I'm using terraform for a couple of projects and I used to write down small quick start guides for others working on the same projects and of course, for my future self. I now decided to pull together all this information and share them publicly. I hope this will help others to get things up and running. I'm also hoping for feedback and improvements I can apply.

This is a guide for small pockets. I'm only using terraform open source, nothing paid. So everyone can benefit from this.

![Man and woman terraforming mars](.images/man-and-woman-terraforming-mars.jpg "Man and woman terraforming mars")
You will not be terraforming mars after you managed to terraform your infrastructure through pipelines, but it feels quite heroic on a small scale anyway. (Photo by [Jake Young
Donate](https://www.pexels.com/photo/photo-of-man-and-woman-looking-at-the-sky-732894/))

## Naming convention

I'm using the following naming convention for my terraform projects:

Terraform Module `terraform-provider-modulename` e.g. `terraform-azurerm-vmwindowsserver` or `terraform-azuredevops-project`

Consumer projects `subscription-function`

Documentation: `terraform-docs` or `terraform-guide`

Versioning: git tags

Microsoft naming suggestion: [azure-best-practices/resource-naming](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)

Terraform - tfm
Sandbox - sbx
Switzerland North - chnorth

Resource Group: rg-tfm-sbx-chnorth-001
Storage Account: sttfmsbxchnorth001 (no dashes allowed, max 24 characters)

## Pipeline templates

I am using a separate `CiCentral` repository for pipeline templates. This allows me to share templates across multiple projects and to keep the project repositories clean.

## A word about stages

I need to frequently test things. For this I've set up a Terraform pipeline that creates different stages also known as workspaces in Terraform:

- DEV: a very short-lived environment that is created with limited resources. This instance can be destroyed every night automatically for cost-saving reasons.
- TST: a near-production system.
- PRD: production, for cost-saving aspects resources for this environment was reserved at Azure for a long timeframe.

## Documentation

[`terraform-docs`](https://github.com/terraform-docs/terraform-docs) is a utility to generate documentation from Terraform modules in various output formats. Install `terraform-docs` using Homebrew (on macOS) or download the binary from the GitHub releases page:

```bash
brew install terraform-docs
```

Make use of `description` parameter in `variables.tf` to ensure useful content in the generated docs. If you want to include the output of `terraform-docs` into an existing readme, insert `BEGIN_TF_DOCS` and `END_TF_DOCS` into your existing `README.md` file.

You can manually run `terraform-docs`:

```bash
terraform-docs markdown table --output-file README.md --output-mode inject .
```

Or use it in a pipeline:

```yaml
steps:
  - name: Generate Documentation
    run: |
      terraform-docs markdown table . > README.md
      git add README.md
      git commit -m "Update documentation"
      git push
```

TODO: discuss usage and usefulness of graph diagramms

- Review [terraform-graph-beautifier](https://github.com/pcasteran/terraform-graph-beautifier)

```bash
terraform graph | terraform-graph-beautifier \
    --output-type=cyto-html \
    > terraform-graph.html
```

## Prerequisites for Terraform

### Working with secrets

Depending on where terraform is running, I'm using one of these two things to store secrets and I'm going to refer to these in the text:

- when I'm testing locally, I'm using an `azure.conf` file which must be excluded from git, you never want to commit these secrets to a repo
- when terraform is executed in an automated build pipeline, I'm using Azure Pipelines and the variable groups in the library there

I will explain both in detail further down in this example.

### Working with environment variables

I'm heavily using environment variables throughout this example. Whenever you see something like `$APP_ID` with a dollar sign at the beginning you can be sure this variable must be set before. I'm not always mentioning that step.

### Service principal

If you need to create a new service principal:

```bash
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUB_ID"
```

Update the variables `subscription_id`, `tenant_id`, `client_id` and `client_secret` in your local `azure.conf`.

Debugging if you have a service principal already and it's not working. One reason can be to have expired credentials.

```bash
az ad sp list --show-mine
az role assignment list --assignee $APP_ID
az ad sp credential reset --name $APP_ID
az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID
az login
az account set --subscription $SUB_ID
```

### Storage account for state files

```bash
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --kind StorageV2 \
  --sku Standard_LRS \
  --https-only true \
  --allow-blob-public-access false
```

If you have already a storage account, you can check it with:

```bash
az account list --output table
az account set --subscription $SUB_ID
az storage account list -g $RESOURCE_GROUP
az storage account show -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT
```

If you need to create a container:

```bash
az storage container create -n tfstate --account-name stdefaultkstjj001 --account-key <YourAzureStorageAccountKey>
```

## Automated process with pipelines

All required credentials are stored in a variable library and are used by the pipeline. There is no need to set anything up locally. The required variables in the library are:

- `storage_account_name`= the name of the storage account, where the terraform state file is located
- `resource_group_name`= the name of the resource group the storage account is in
- `container_name`= "tfstate"
- `key`= "terraform.tfstate"
- `subscription_id`= your subscription id
- `tenant_id`= your tenant id
- `client_id`= your app id
- `client_secret`= your app password

Within a pipeline yaml file you can make use of these variables like this:

````yaml
stages:
  - stage: DEV
    condition: in('${{ parameters.stage }}', 'DEV')
    jobs:
      - job: DEV_setup
        steps:
          - script: |
              terraform init \
              -backend-config="storage_account_name=$(storage_account_name)" \
              -backend-config="resource_group_name=$(resource_group_name)" \
              -backend-config="container_name=$(container_name)" \
              -backend-config="key=$(key)" \
              -backend-config="subscription_id=$(subscription_id)" \
              -backend-config="tenant_id=$(tenant_id)" \
              -backend-config="client_id=$(client_id)" \
              -backend-config="client_secret=$(client_secret)"
            displayName: 'Terraform: init'
````

## Local development & test

If you don't want to make use of pipelines, create an `azure.conf` file with the following content. **Important Note**: your `azure.conf` file must be added to your `.gitignore` file and should never be committed to a repository. It must contain something like this:

```conf
# azure.conf, must be in .gitignore
tenant_id="$TENANT_ID"
subscription_id="$SUB_ID"
resource_group_name="$RESOURCE_GROUP"
storage_account_name="$STORAGE_ACCOUNT"
container_name="tfstate-pqe"
key="terraform.tfstate"
```

If besides Microsoft Azure also AWS ressources should be created, the AWS credentials should be placed within a `aws.conf` file:

```conf
[default]
region = us-east-1
aws_access_key_id = AKIA************
aws_secret_access_key = *********************
```

Then run the different steps of the pipeline manually. Ensure to use the right workspace name which equals the stage you are going to deploy.

```bash
# Prepare
terraform init -backend-config=azure.conf
terraform workspace select -or-create=true 'sbx'

# Ensure formatting and documentation
terraform fmt -recursive
terraform-docs markdown table --sort-by required --output-file README.md --output-mode inject .

# Plan and apply
terraform plan -out out.plan
terraform apply out.plan

# Destroy
terraform plan -destroy -out out.plan
terraform apply out.plan
```

## Structure of terraform

A Terraform project can be structured in different files. When you are working on your own you can put all in one file. But the bigger your project gets and when more people are working on it, it makes sense to separate things.

### `azure.conf`

Secret management is done like I described it [above](#-working-with-secrets) either in a local `azure.conf` or in variable groups which can be used in pipelines. So for testing locally you would need a `azure.conf` file.

Hint: ensure the container mentioned in the backend configuration is created in the Azure storage.

### `workspacetest.sh`

[This script](#-a-word-about-stages) will be used to switch between workspaces which are used as stages e.g. development (DEV), test (TST) and production (PRD).

### `backend.tf`

I'm storing the state of my infrastructure in general in an Azure storage. You could also define a local storage here if you are testing things and do not share the state with other developers.

### `provider.tf`

The Azure Resource Manager [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) will be used as provider to create resources. There are a bunch of providers available. I'm mostly using Azure stuff and Proxmox.

### `variables.tf`

This file contains everything which can be adjusted. There are some general variables like Azure region and resource group names, specific variables that are related to the actuale infrastructure we are creating and I'm also defining tags here which are used to organize resources.

### `terraform.tfvars`

This is a special file where you can put the content of variables you are specifying in `variables.tf`. Make sure to never commit this file to a repo. I'm using this for example to store my public ssh key I want to use for the connection to VMs I create with terraform.

### `main.tf`

In this file the magic happens. All the resources are created. You can split this file even further if it becomes too complex.

### `output.tf`

This contains the output terraform is returning when done. I don't need that often.

## Working with Azure pipelines, Terraform modules and Proxmox

Often you will create similar ressources e.g. VM's with network security groups and storage. You can create a module so that you don't have to re-do all of this over and over again and most important: when you improve your modules, these improvements can be applies to all your terraform projects which make use of the module. These modules are best organized in a Terraform registry. There is a public one at [registry.terraform.io](https://registry.terraform.io/browse/modules), you can use a private with teh terraform Cloud service and you can also use private git repos. All these options have different pros and cons. I'll show you how to use private git repos as this is an option with many benefits and you are not bound to an additional extaernal service.

Some key aspects you sbhould consider:

- if you want some kind of versioning, you have to work with tags
- the process is intended to work loosly coupled, meaning every terraform step can be executed with some delay inbetween e.g. for manual gateways. This means terraform files (work results like a created plan file) must be stored.
- I have some VMs and LXC containers which are provisioned via Proxmox. For those provisioning steps I have a dedicated SSH key pair for the pipeline job in Azure DevOps. I opted for an SSH key with password. Both must be stored in the Azure Pipeline Library side by side which might sound stupid. But when the SSH key get's lost or stolen somehow, changes are still that the password is not stolen and your VM's and LCX's are still save.
- I have a custom Azure DevOps Build Agent running. For details see: [Run as a systemd service](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/v2-linux?view=azure-devops#run-as-a-systemd-service). This agent is required because public build agents are not allowed to access the LAN where Proxmox is located.

## Replacing ressources

I had to recreate a LCX container and wondered how to do this with terraform. I found the [replace](https://developer.hashicorp.com/terraform/cli/commands/plan#replace-address) option for the `terraform apply` command which is exactly what I needed. I'm using it like this:

```bash
terraform apply -replace="module.lxc-portainer.proxmox_lxc.basic"
```

## What to do next

You could:

- [deploy a Azure Kubernetes Service (AKS) with portainer and terraform](https://github.com/xware-gmbh/aks-terraform-portainer)
- [deploy a Portainer business control node on Azure Container Instances (ACI)](https://github.com/xware-gmbh/portainer-control-node-example)
