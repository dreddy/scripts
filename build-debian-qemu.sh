#!/bin/bash


if [ $USER != "root" ] ; then
    echo "Restarting script with sudo..."
    sudo -E $0 ${*}
    exit
fi

if [ "$#" = 0 ]
then
    echo "Error: Valid arguments are <hostname> <qcow2 filename> <disk size> "
    echo "Example: build-debian-image dreddy-image1 debian-testing.qcow2 10G "
    exit -1
fi



HOSTNAME="$1"
DISKNAME="$2"
DISK_SZ="$3"

NBD_DEV=/dev/nbd0 

# From now on, abort on error
set -e

# Create image file, unless reusing an existing one
echo "Creating image"
qemu-img create -f qcow2 ${DISKNAME} ${DISK_SZ}

echo "Probing module"
modprobe nbd

echo "Mounting image on $NBD_DEV"
qemu-nbd -c $NBD_DEV ${DISKNAME}

parted -s -a optimal -- /dev/nbd0 \
  mklabel gpt \
  mkpart primary fat32 1MiB 512MiB \
  mkpart primary ext4 512MiB -0 \
  name 1 uefi \
  name 2 root \
  set 1 esp on

sleep 2

mkfs.fat -F 32 -n EFI /dev/nbd0p1
mkfs.ext4 -L root /dev/nbd0p2

ROOT_UUID="$(blkid | grep "^${NBD_DEV}p[0-9]\+:" | grep ' LABEL="root" ' | grep -o ' UUID="[^"]\+"' | sed -e 's/^ //' )"
EFI_UUID="$(blkid | grep "^${NBD_DEV}p[0-9]\+:" | grep ' LABEL="EFI" ' | grep -o ' UUID="[^"]\+"' | sed -e 's/^ //' )"

echo "Root: $ROOT_UUID"
echo "EFI: $EFI_UUID"

echo "Mounting for chroot"
mount $ROOT_UUID /mnt
[[ -d /mnt/boot/efi ]] || mkdir -p /mnt/boot/efi
mount $EFI_UUID /mnt/boot/efi

echo "Bootstrapping debian"
debootstrap --arch amd64 --components=main,contrib,non-free testing /mnt http://deb.debian.org/debian/

echo "Mounting proc, dev and sys"
mount -o bind,ro /dev /mnt/dev
mount -t proc none /mnt/proc
mount -t sysfs none /mnt/sys

echo "Preparing stage 2"
cat > /mnt/root/stage-2-setup.bash <<EOF
#!/bin/bash

set -e # Abort on error

export DEBIAN_FRONTEND=noninteractive

echo "Configuring fstab"
cat > /etc/fstab <<S2EOF
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
$ROOT_UUID / ext4 errors=remount-ro 0 1
$EFI_UUID /boot/efi vfat defaults 0 1
S2EOF
cat /etc/fstab

echo "...mounting"
[[ -d /boot/efi ]] || mkdir /boot/efi
mount -a

echo "--------------------------------------------"

echo "Setting timezone"
debconf-set-selections <<S2EOF
tzdata tzdata/Areas select America
tzdata tzdata/Zones/America select Los_Angeles
S2EOF
# This is necessary as tzdata will assume these are manually set and override the debconf values with their settings
rm -f /etc/localtime /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

echo "--------------------------------------------"

echo "Configuring networking"
echo "...lo"
cat - >>/etc/network/interaces <<S2EOF

auto lo
iface lo inet loopback
S2EOF

echo "...enp1s0"
cat - >/etc/network/interfaces.d/enp1s0 <<S2EOF
allow-hotplug enp1s0
iface enp1s0 inet dhcp
S2EOF

echo "Configuring hostname"
echo "$HOSTNAME" > /etc/hostname

echo "Setting up /etc/hosts"
cat - >/etc/hosts <<S2EOF
127.0.0.1       localhost
127.0.1.1       $HOSTNAME.$DOMAIN_NAME $HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
S2EOF

echo "--------------------------------------------"

echo "Configuring apt sources"

cat - >/etc/apt/sources.list <<S2EOF
deb http://ftp.us.debian.org/debian/ testing main non-free contrib
deb-src http://ftp.us.debian.org/debian/ testing main non-free contrib

deb http://security.debian.org/debian-security testing-security main contrib non-free
deb-src http://security.debian.org/debian-security testing-security main contrib non-free

S2EOF

cat - >/etc/apt/apt.conf << S2EOF
Acquire::http::Proxy "http://proxy-chain.intel.com:911/";
APT::Default-Release "testing";

S2EOF

apt-get -qq -y update

echo "--------------------------------------------"

echo "Configuring locales and keyboard"
debconf-set-selections <<S2EOF
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8
locales locales/default_environment_locale select en_US.UTF-8
S2EOF
apt-get -qq -y install locales console-setup

echo "--------------------------------------------"

echo "Installing kernel"
apt-get -qq -y install linux-image-amd64

echo "--------------------------------------------"

echo "Installing bootloader"
apt-get -qq -y install grub-efi-amd64
# Add console=ttyS0 so we get early boot messages on the serial console.
sed -i -e 's/^\\(GRUB_CMDLINE_LINUX="[^"]*\\)"$/\\1 console=ttyS0"/' /etc/default/grub
cat - >>/etc/default/grub <<S2EOF
GRUB_TERMINAL="serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=9600 --stop=1"
S2EOF
grub-install --target=x86_64-efi
update-grub

echo "Copying fallback bootloader"
mkdir /boot/efi/EFI/BOOT
cp /boot/efi/EFI/debian/fbx64.efi /boot/efi/EFI/BOOT/bootx64.efi

echo "--------------------------------------------"

echo "Enabling serial console"
systemctl enable serial-getty@ttyS0.service

echo "--------------------------------------------"

if [[ -n '$ROOT_PASSWD' ]]
then
	echo "Setting root password"
	echo 'root:$ROOT_PASSWD' | chpasswd -e
	echo "--------------------------------------------"
fi

echo "Tidying..."
apt-get clean

echo "=== STAGE 2 SUCCESSFULLY REACHED THE END ==="
EOF

echo "Running stage 2 script in chroot"
LANG=C.UTF-8 chroot /mnt /bin/bash /root/stage-2-setup.bash

#echo "Removing stage 2 script"
#rm /mnt/root/stage-2-setup.bash

echo "Unmounting chroot"
umount /mnt/dev /mnt/proc /mnt/sys /mnt/boot/efi /mnt

echo "Disconnecting $NBD_DEV"
sync
qemu-nbd -d $NBD_DEV

