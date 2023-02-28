#!/bin/bash
#
# Build a generic root file system based on the Kalopa RoboBSD image. This
# image doesn't have any specific boat data or applications, so those
# need to be installed, after this.
#
set -e

: ${DISK=/disk}
: ${MISSION=/missions/mission.yaml}
: ${OUTPUT=$DISK/simulate.qcow}

ROOTFS=$DISK/rootfs
IMGDIR=$DISK/images

image="robobsd.alix.img.gz"
base_file="$IMGDIR/$image"
root_disk="$DISK/root_disk.img"

echo "***** Generate a new RoboBSD (QCOW) disk image *****"

sudo rm -rf $ROOTFS
mkdir -p \
	$IMGDIR \
	$ROOTFS/app/bin \
	$ROOTFS/app/log \
	$ROOTFS/app/rc.d \
	$ROOTFS/app/tmp \
	$ROOTFS/cfg

if [ ! -s $root_disk -o $root_disk -ot $base_file ]
then
	if [ ! -s $base_file ]
	then
		echo ">> Downloading a RoboBSD disk image from Kalopa..."
		curl -Lo $base_file https://kalopa.com/download/robobsd/$image
	fi
	echo ">> Uncompressing root (base) disk image..."
	rm -f $root_disk
	gunzip < $base_file > $root_disk
fi

echo ">> Preparing RoboBSD QCOW image for QEMU..."
rm -f $sim_disk
qemu-img create -f qcow2 -F raw -b $root_disk $OUTPUT

echo ">> Copying default files to $ROOTFS..."
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
(cd $ROOTFS/app/tmp && \
	gem fetch io-console -v 0.6.0 && \
	gem fetch reline -v 0.3.2 && \
	gem fetch irb -v 1.6.2 && \
	gem fetch connection_pool -v 2.3.0 && \
	gem fetch redis-client -v 0.12.2 && \
	gem fetch redis -v 5.0.6 && \
	gem fetch serialport -v 1.3.2 && \
	gem fetch msgpack -v 1.6.0 && \
	gem fetch json -v 2.6.3 && \
	gem fetch securerandom -v 0.2.2 && \
	gem fetch yaml -v 0.2.1 && \
	gem fetch god -v 0.13.7)

if [ -d ../sgslib ]
then
	#
	# Pull the SGSLIB gem from local sources
	echo ">> Copying SGSLIB gem to $ROOTFS..."
	(cd ../sgslib && git pull)
	sgs_path=$(cd ../sgslib && rake build | sed 's/.* built to //' | sed 's/\.$//')
	cp ../sgslib/$sgs_path $ROOTFS/app/tmp
else
	#
	# Install the latest release of SGSLIB
	(cd $ROOTFS/app/tmp && gem fetch --silent sgslib)
fi

#
# Copy a mission file into place
echo ">> Copying mission file to $ROOTFS..."
echo "Mission: $(grep title: $MISSION | sed 's/.*title://')"
sudo cp $MISSION $ROOTFS/app/mission.yaml

echo ">> Making a FAT configuration file system..."

#
# Create and mount the FAT file system
echo ">> Generating a FAT file system"
mkdir -p $DISK/mnt
dd if=/dev/zero bs=1024k count=100 of=$DISK/config_fs.raw
mkfs.fat $DISK/config_fs.raw
sudo mount -o loop $DISK/config_fs.raw $DISK/mnt

#
# Build the tarball
echo ">> Installing our packages onto the FAT fs"
sudo cp files/install.sh $DISK/mnt/INSTALL.SH
sudo tar czf $DISK/mnt/FILES.TGZ -C $DISK/rootfs .

#
# Now unmount the file system.
sync; sync; sync
sudo umount $DISK/mnt
rm -rf $DISK/mnt

echo ">> Booting the kernel to install the custom bits..."
/usr/bin/expect ./install.exp $OUTPUT $DISK/config_fs.raw

echo "***** Your simulation image is: $OUTPUT *****"
exit 0
