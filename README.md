# Terraform quick start guide

I'm using terraform for a couple of projects and I used to write down a small quick start guides for others working on the same projects and of course, for my future self. I now decided to scrap this information altogether and share them publicly. I hope this will help others to get things up and running. I'm also hoping for feedback and improvements I can apply.

This is a guide for small pockets. I'm only using terraform open source, nothing paid. So everyone can benefit from this.

![Man and woman terraforming mars](.images/man-and-woman-terraforming-mars.jpg "Man and woman terraforming mars")
You will not be terraforming mars after you managed to terraform your infrastructure through pipelines, but it feels quite heroic on a small scale anyway. (Photo by [Jake Young
Donate ](https://www.pexels.com/photo/photo-of-man-and-woman-looking-at-the-sky-732894/))

## A word about stages

I need to frequently test things. For this I've set up a Terraform pipeline that creates different environments:

- DEV: a very short-lived environment that is created with limited resources. This instance can be destroyed every night automatically for cost-saving reasons.
- TST: a near-production system.
- PRD: production, for cost-saving aspects resources for this environment was reserved at Azure for a long timeframe.

## Prerequisites for Terraform

- A service principal
- A storage account for Terraform state file.

### Working with secrets

Depending on where terraform is running, I'm using one of these two things to store secrets and I'm going to refer to these in the text:

- when I'm testing locally, I'm using an `azure.conf` file which must be excluded from git, you never want to commit these secrets to a repo
- when terraform is executed in an automated build pipeline, I'm using Azure Pipelines and the variable groups in the library there

I will explain both in detail further down in this example.

### Working with environment variables

I'm heavily using environment variables throughout this example. Whenever you see something like `$APP_ID` with a dollar sign at the beginning you can be sure this variable must be set before. I'm not always mentioning that step.

### Service principal

If you need to create a new service principal:
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/$SUB_ID"
```

Update the variables `subscription_id`, `tenant_id`, `client_id` and `client_secret` in your local `azure.conf`.

Debugging if you have a service principal already and it's not working. One reason can be to have expired credentials.

```
az ad sp list --show-mine
az role assignment list --assignee $APP_ID
az ad sp credential reset --name $APP_ID
az login --service-principal --username $APP_ID --password $PASSWORD --tenant $TENANT_ID
az login
az account set --subscription $SUB_ID
```

### Storage account

```
$ az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --kind StorageV2 \
  --sku Standard_LRS \
  --https-only true \
  --allow-blob-public-access false
```

If you have already a storage account, you can check it with:

```
$ az account list --output table
$ az account set --subscription $SUB_ID
$ az storage account list -g $RESOURCE_GROUP
$ az storage account show -g $RESOURCE_GROUP -n $STORAGE_ACCOUNT
```

If you need to create a container:

```
az storage container create -n tfstate --account-name stdefaultkstjj001 --account-key <YourAzureStorageAccountKey>
```

## Automated process with pipelines

All required credentials are stored in a variable library and are used by the pipeline. There is no need to set anything up locally. The required variables in the library are:

- `storage_account_name`= the name of the storage account, where the terraform state file is located
- `resource_group_name`= the name of the resource group the storage account is in
- `container_name`= "tfstate-k8s"
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

```
# azure.conf, must be in .gitignore
storage_account_name="$STORAGE_ACCOUNT"
resource_group_name="$RESOURCE_GROUP"
container_name="tfstate-k8s"
key="terraform.tfstate"
subscription_id="$SUB_ID"
tenant_id="$TENANT_ID"
client_id="$APP_ID"
client_secret="$PASSWORD"
```

Then run the different steps of the pipeline manually. Ensure to use the right workspace name which equals the stage you are going to deploy.

```
$ terraform init -backend-config=azure.conf
$ ./workspacetest.sh DEV
$ terraform plan -out out.plan
$ terraform apply out.plan
```

## What to do next

You could:

- [deploy a Azure Kubernetes Service (AKS) with portainer and terraform](https://github.com/xware-gmbh/aks-terraform-portainer)
- [deploy a Portainer business control node on Azure Container Instances (ACI)](https://github.com/xware-gmbh/portainer-control-node-example)
