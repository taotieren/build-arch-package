#!/bin/bash -ex

if [ -z "$INPUT_BUILDING" ] || [ -z "$INPUT_PKGBUILD" ] || [ -z "$INPUT_OUTDIR" ] || [ -z "$GITHUB_SHA" ]; then
    echo 'Missing environment variables'
    exit 1
fi

# Resolve environment paths
INPUT_BUILDING="$(eval echo $INPUT_BUILDING)"
INPUT_PKGBUILD="$(eval echo $INPUT_PKGBUILD)"
INPUT_DEPENDS="$(eval echo $INPUT_DEPENDS)"
INPUT_OUTDIR="$(eval echo $INPUT_OUTDIR)"

# Add ArchLinuxCN mirrors
cat  >> /etc/pacman.conf << EOF
[archlinuxcn]
Server = https://mirror.xtom.com.hk/archlinuxcn/$arch
EOF


# Get PKGBUILD dir
PKGBUILD_DIR=$(dirname $(readlink -f $INPUT_PKGBUILD))
pacman -Syu --noconfirm --noprogressbar --needed archlinuxcn-keyring

pacman -Syu --noconfirm --noprogressbar --needed base-devel btrfs-progs dbus sudo

pacman -Syu --noconfirm --noprogressbar --needed devtools-cn

dbus-uuidgen --ensure=/etc/machine-id

sed -i "s|MAKEFLAGS=.*|MAKEFLAGS=-j$(nproc)|" /etc/makepkg.conf
useradd -m user
cd /home/user

# Copy PKGBUILD and * scripts
cp "$PKGBUILD_DIR"/* ./ || true
sed "s|%COMMIT%|$GITHUB_SHA|" "$INPUT_PKGBUILD" > PKGBUILD
chown user PKGBUILD

# Build the package
# See：https://wiki.archlinux.org/index.php/DeveloperWiki:Building_in_a_clean_chroot
$INPUT_BUILDING -- -U user -I $INPUT_DEPENDS 

# Save the artifacts
mkdir -p "$INPUT_OUTDIR"
cp *.pkg.* "$INPUT_OUTDIR"/
