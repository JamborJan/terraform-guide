# Restic Backup in LCX Container on Proxmox

## Quick intro

Ensure `azure.conf` and `terraform.tfvars` are there and the specified tf container exists on the azure storage.

```bash
cd 002-docker-compose/restic/prx-minio
terraform init -backend-config=azure.conf
./workspacetest.sh PRD
terraform plan -out out.plan
terraform apply out.plan

terraform plan -destroy -out out.plan
terraform apply out.plan
```

## Infrastructure

Terraform creates infra on Proxmox. Requirements:
- Terraform user with atequate permissions




## Restic

To initialize restic and backup stuff, see [Microsoft Azure Blob Storage](https://restic.readthedocs.io/en/latest/030_preparing_a_new_repo.html#microsoft-azure-blob-storage).

Set keys for manual setup

```bash
export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<SECRET_KEY>
```

Prepare target. Ensure to have the environments variables above set.

```bash
restic -r azure:backup:/ init
```

Backup 

```bash
restic -r azure:backup:/ --verbose backup /data/buecher
```

List of folders:

Backup to Azure Blob
- [OK] buecher
- [OK] buecher-archiv
- [OK] data
- [OK] eigene
- [ ] container

Backup nach NAS
- [ ] filme
- [ ] musik
- [ ] serien
- [ ] video

Kein backup
- [ ] filme-archiv
- [ ] musik-archiv
- [ ] serien-archiv

Backup with scheduled plan: see [crontab_config.yml](../../crontab/crontab_config.yml)

```bash
docker exec restic /usr/bin/restic --verbose=3 backup /data/buecher-archiv
```

See Snapshots

```bash
docker exec restic /usr/bin/restic snapshots
restic snapshots
```

Browse repo
- Not working on mac, see: https://github.com/restic/restic/pull/3680

```bash
brew install restic
brew install --cask macfuse

export AZURE_ACCOUNT_NAME=<ACCOUNT_NAME>
export AZURE_ACCOUNT_KEY=<SECRET_KEY>
export RESTIC_PASSWORD=<RESTIC_PASSWORD>
export RESTIC_REPOSITORY=<RESTIC_REPOSITORY>

restic snapshots

mkdir ~/restic
restic mount ~/restic
```

```bash
docker exec restic mkdir /mnt/restic
docker exec restic ls /mnt/
docker exec restic /usr/bin/restic mount /mnt/restic
```

Clean up snapshots

```bash
restic forget --keep-last 1 --prune
docker exec restic /usr/bin/restic forget --keep-last 1 --prune
```
