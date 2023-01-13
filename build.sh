#!/bin/sh
#
# Build a generic root file system based on the Kalopa RoboBSD image. This
# image doesn't have any specific boat data or applications, so those
# need to be installed, after this.
#
set -e

: ${BSDIR=$HOME/bsdisk}
ROOTFS=$BSDIR/rootfs
IMGDIR=$BSDIR/images

image="robobsd.alix.img.gz"
local_file="$IMGDIR/$image"

echo "***** PHASE I - Generate a new RoboBSD disk image *****"

mkdir -p $BSDIR $ROOTFS $IMGDIR
if [ ! -s $local_file ]
then
	echo ">> Downloading a RoboBSD disk image from Kalopa..."
	curl -Lo $local_file https://kalopa.com/download/robobsd/$image
fi

echo ">> Preparing RoboBSD image for QEMU..."
rm -f $BSDIR/root_disk.img
gunzip < $local_file > $BSDIR/root_disk.img


echo "***** PHASE II - Create a configuration image *****"

echo ">> Copying default files to $ROOTFS..."
sudo rm -rf $ROOTFS
mkdir -p $ROOTFS/app/bin \
	$ROOTFS/app/log \
	$ROOTFS/app/rc.d \
	$ROOTFS/app/tmp \
	$ROOTFS/cfg

cp -r files/cfg $ROOTFS
sudo chown 0:0 $ROOTFS $ROOTFS/app
sudo chown -R 0:0 $ROOTFS/app/bin $ROOTFS/app/log $ROOTFS/app/rc.d $ROOTFS/cfg
#sudo chown -R 1000:1000 $ROOTFS/app/robobsd

# Get the GPS time app
echo ">> Downloading latest gps_time to $ROOTFS..."
git clone -q --depth=1 --branch=main https://github.com/kalopa/gps_time.git $ROOTFS/app/tmp/gps_time
rm -rf $ROOTFS/app/tmp/gps_time/.git

#
# Pull all the required gems
echo ">> Downloading/copying Ruby gems to $ROOTFS..."
gem fetch --silent \
	io-console:0.5.7 \
	reline:0.3.1 \
	irb:1.3.5 \
	redis:4.7.1 \
	serialport:1.3.2 \
	msgpack:1.5.2 \
	json:2.6.3 \
	securerandom:0.1.0 \
	yaml:0.1.1 \
	god:0.13.7
mv *.gem $ROOTFS/app/tmp

#
# Pull the SGSLIB gem from local sources
echo ">> Copying SGSLIB gem to $ROOTFS..."
(cd ../sgslib && git pull)
sgs_path=$(cd ../sgslib && rake build | sed 's/.* built to //' | sed 's/\.$//')
cp ../sgslib/$sgs_path $ROOTFS/app/tmp

#
# Copy a mission file into place
echo ">> Copying mission file to $ROOTFS..."
echo "Mission: $(grep title: missions/current | sed 's/.*title://')"
sudo cp missions/current $ROOTFS/app/mission.yaml

echo "***** PHASE III - Make a FAT configuration file system *****"

#
# Create and mount the FAT file system
echo ">> Generating a FAT file system"
mkdir -p $BSDIR/mnt
dd if=/dev/zero bs=1024k count=100 of=$BSDIR/config_fs.raw
mkfs.fat $BSDIR/config_fs.raw
sudo mount -o loop $BSDIR/config_fs.raw $BSDIR/mnt

#
# Build the tarball
echo ">> Installing our packages onto the FAT fs"
sudo cp files/install.sh $BSDIR/mnt/INSTALL.SH
sudo tar czf $BSDIR/mnt/FILES.TGZ -C $BSDIR/rootfs .

#
# Now unmount the file system.
sync; sync; sync
sudo umount $BSDIR/mnt
rm -rf $BSDIR/mnt

echo "***** PHASE IV - Boot the system to perform configuration steps *****"

/usr/bin/expect ./install.exp $BSDIR/root_disk.img $BSDIR/config_fs.raw

fmt <<EOF
**********

Now save the file $BSDIR/root_disk.img as an SGS disk image. You are
ready to run a simulation using boatsim...

**********
EOF
exit 0
