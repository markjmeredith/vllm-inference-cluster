#!/bin/bash
mount_dir=$1
part_label=$2

# Look for existing partition
storage_part=$(find -L /dev/v* -samefile "/dev/disk/by-label/$part_label" 2> /dev/null)
if [[ -z "$storage_part" ]]; then
    echo Initialize block storage

    # Find the boot device
    efi_part=$(find -L /dev/v* -samefile /dev/disk/by-label/UEFI)
    efi_dev=$(lsblk -no pkname "$efi_part")
    echo "Boot device: $efi_dev"

    # Find the new storage device
    storage_id=$(stat -c%N /dev/disk/by-id/virtio* | grep -v -e "$efi_dev" -e "cloud" -e "part" | awk '{print $1}' | tr -d "'")
    storage_dev=$(find -L /dev/v* -samefile "$storage_id" 2> /dev/null)
    storage_part=${storage_dev}1
    echo "Block storage: $storage_dev"

    # Partition local storage
    echo 'type=83' | sfdisk "$storage_dev"
    mkfs.ext4 "$storage_part"
    e2label "$storage_part" "$part_label"
fi

# Mount local storage
mkdir -p "$mount_dir" 2>/dev/null
echo "Mount storage $storage_part @ $mount_dir"
echo "$storage_part $mount_dir ext4 defaults 0 2" >> /etc/fstab
mount -a
