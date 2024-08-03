#!/bin/bash

# Update and upgrade the system
apt update -y && apt upgrade -y

# Install necessary packages
apt install grub2 wimtools ntfs-3g -y

# Define specific partition sizes in MB
part1_size_mb=25600  # Size for the first partition
part2_size_mb=25600  # Size for the second partition

# Create a GPT partition table
parted /dev/sda --script -- mklabel gpt

# Create the first partition
parted /dev/sda --script -- mkpart primary ntfs 1MB ${part1_size_mb}MB

# Create the second partition
parted /dev/sda --script -- mkpart primary ntfs ${part1_size_mb}MB $((part1_size_mb + part2_size_mb))MB

# Inform the kernel of the partition table changes
partprobe /dev/sda

# Wait for the system to register the changes
sleep 30
partprobe /dev/sda

sleep 30
partprobe /dev/sda

sleep 30


#Format the partitions
mkfs.ntfs -f /dev/sda1
mkfs.ntfs -f /dev/sda2

echo "NTFS partitions created"

echo -e "r\ng\np\nw\nY\n" | gdisk /dev/sda

mount /dev/sda1 /mnt

#Prepare directory for the Windows disk
cd ~
mkdir windisk

mount /dev/sda2 windisk

grub-install --root-directory=/mnt /dev/sda

#Edit GRUB configuration
cd /mnt/boot/grub
cat <<EOF > grub.cfg
menuentry "windows installer" {
	insmod ntfs
	search --set=root --file=/bootmgr
	ntldr /bootmgr
	boot
}
EOF

cd /root/windisk

mkdir winfile

wget -O win10.iso --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" https://rb.gy/qpd6bs

mount -o loop win10.iso winfile

rsync -avz --progress winfile/* /mnt

umount winfile

wget -O virtio.iso https://shorturl.at/lsOU3

mount -o loop virtio.iso winfile

mkdir /mnt/sources/virtio

rsync -avz --progress winfile/* /mnt/sources/virtio

cd /mnt/sources

touch cmd.txt

echo 'add virtio /virtio_drivers' >> cmd.txt

wimlib-imagex update boot.wim 2 < cmd.txt

reboot


