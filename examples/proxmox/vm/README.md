# Container infrastructure

## Adjust Proxmox dependencies

```bash
apt update -y && apt install libguestfs-tools -y
```

```text
The following additional packages will be installed:
  acl arch-test augeas-lenses cryptsetup-bin db-util db5.3-util debootstrap exfatprogs extlinux f2fs-tools fonts-droid-fallback fonts-noto-mono fonts-urw-base35 fuse3 gawk ghostscript guestfish guestfs-tools guestmount hfsplus icoutils kpartx ldmtool libafflib0v5 libaugeas0 libbfio1 libconfig9 libdate-manip-perl libdeflate0 libewf2 libfontenc1 libgs-common libgs10 libgs10-common libguestfs-hfsplus libguestfs-perl libguestfs-reiserfs libguestfs-xfs libguestfs0 libhfsp0 libhivex0 libice6 libidn12 libijs-0.35 libintl-perl libintl-xs-perl libjbig0 libjbig2dec0 liblcms2-2 libldm-1.0-0 liblerc4 libmpfr6 libnetpbm11 libntfs-3g89 libopenjp2-7 libpaper-utils libpaper1 libparted2 librpm9 librpmio9 libsigsegv2 libsm6 libssh-4 libsys-virt-perl libtiff6 libtsk19 libvhdi1 libvirt-l10n libvirt0 libvmdk1 libwebp7 libwin-hivex-perl libxml-xpath-perl libxt6 libyajl2 libyara9 lsscsi mdadm mtools netpbm ntfs-3g osinfo-db parted poppler-data reiserfsprogs rpm-common scrub sleuthkit squashfs-tools supermin syslinux syslinux-common uuid-runtime virt-p2v x11-common xfonts-encodings xfonts-utils zerofree
```

## Prepare base image and create template

I am working in `/opt/ubuntu`.

Get the image:

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

Install the guest agent in the image:

```bash
virt-customize -a noble-server-cloudimg-amd64.img --install qemu-guest-agent
```

Create a template:

```bash
VMID=9000 && \
qm create $VMID \
    --name "ubuntu-cloudinit-template" \
    --memory 2048 \
    --cores 2 \
    --net0 virtio,bridge=vmbr0 \
    --agent=1 && \
qm importdisk $VMID noble-server-cloudimg-amd64.img zfs && \
qm set $VMID \
    --scsihw virtio-scsi-pci \
    --scsi0 zfs:vm-$VMID-disk-0 \
    --boot c \
    --bootdisk scsi0 \
    --ide2 zfs:cloudinit \
    --serial0 socket \
    --vga serial0 && \
qm template $VMID
```

## Manually create VM from template

Clone and update config:

```bash
qm clone 9000 999 --name test-clone-cloud-init
qm set 999 --sshkey id_rsa.pub
qm set 999 --ipconfig0 ip=192.168.100.30/24,gw=192.168.100.1
```

Start:

```bash
qm start 999
```

SSH into the new VM:

```bash
ssh ubuntu@192.168.100.30
```
