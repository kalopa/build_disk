# Set of Utilities to Build an SGS Disk

The Sailboat Guidance System main computer ("Mother") is based
around [RoboBSD](https://github.com/kalopa/robobsd).
There are a number of steps which need to happen in order to produce
a bootable SGS CF image.
These are as follows:

1. Copy (and uncompress) the raw RoboBSD image for the platform.
2. Prepare a tarball with the various packages and config files.
3. Produce a FAT file system based on the tarball/install script.
4. Boot the raw image using QEMU and mount the FAT file system.
5. Unpack the tarball and run the install script.
6. Save the new root filesystem, ready for deployment.

## Build Steps

To build a root image, run this command:

$ ./build.sh

All going well, the system should follow the above steps, including
spinning up a QEMU (i386) virtual machine, logging in, and making
the required changes to the system, before shutting down the VM.

Now rename the file in $BSDIR/root\_disk.img as $BSDIR/sailboat.alix.img
(or equivalent) and compress it if need be.
