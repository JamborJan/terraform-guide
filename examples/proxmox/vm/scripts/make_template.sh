#!/bin/bash
#
# A script to create a flatcar template VM
#
# (c) Lucid Solutions 2023
#
# example usage:
# >  make_template -i flatcar_production_qemu_uefi_image.img -n flatcar-production-qemu-3510.2.6 900
#
set -eu

usage(){
  >&2 cat <<-EOF
Usage: $0
     [ -d | --datastore ]
     [ -v | --verbose ]
     [ -f | --force ]
     [ -n | --name <vm_name> ]
     [ -i | --osimage <qcow2_image> ]
     [ --varsimage <qcow2_image> ]
     [ --codeimage <qcow2_image> ]
     [ -h | --help ]
     <vm_id>
EOF
    exit 1
}

OPTS=$(/usr/bin/getopt -o d:vhn:i: --long verbose,help,name:,osimage:,varsimage:,codeimage:,datastore -n 'make_template' -- "$@")
if [ $? != 0 ] ; then usage >&2 ; exit 1 ; fi
eval set -- "$OPTS"

VERBOSE=false
VARS_IMAGE=flatcar_production_qemu_uefi_efi_vars.fd
CODE_IMAGE=flatcar_production_qemu_uefi_efi_code.fd
OS_IMAGE=flatcar_production_qemu_uefi_image.img
NAME=flatcar-linux
DATASTORE=local
SNIPSTORE=local

while true; do
  case "$1" in
    -v | --verbose ) VERBOSE=true; shift ;;
    -h | --help ) usage; exit 1 ;;
    -n | --name ) NAME="$2"; shift 2 ;;
    --varsimage ) VARS_IMAGE="$2"; shift 2 ;;
    --codeimage ) CODE_IMAGE="$2"; shift 2 ;;
    -i | --image ) OS_IMAGE="$2"; shift 2 ;;
    -d | --datastore ) DATASTORE="$2"; shift 2 ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

if [[ $# -ne 1 ]]; then
  usage
fi
VM_ID=$1

[ -n "$VERBOSE" ] && echo "Create VM ${VM_ID} (${NAME} from ${OS_IMAGE})"
qm create ${VM_ID} \
    --name "${NAME}" \
    --agent=1 \
    --bios=ovmf \
    --cores=1 \
    --ostype l26 \
    --scsihw virtio-scsi-single \
    --boot order=scsi0 \
    --hookscript ${SNIPSTORE}:snippets/multi-hookscript.pl \
    --efidisk0 "file=${DATASTORE}:0,import-from=$(readlink -e ${VARS_IMAGE}),format=raw,efitype=4m,pre-enrolled-keys=1" \
    --scsi0 "file=${DATASTORE}:0,import-from=$(readlink -e ${OS_IMAGE}),format=qcow2" \
    --description "Flatcar Template with Ignition configuration" \
    --tag "flatcar,template"

#  Convert the VM to a template
[ -n "$VERBOSE" ] && echo "Convert VM ${VM_ID} to a template"
qm template ${VM_ID}

[ -n "$VERBOSE" ] && echo "Template VM ${VM_ID} done"