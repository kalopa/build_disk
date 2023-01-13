#/bin/sh
#
# Running on a vanilla RoboBSD system, install the various files
# needed for the boat.
#
set -e

echo ">> Perform initial steps prior to unpacking tarball."
cd /
mount -w / && /usr/bin/true
mount -w /cfg && /usr/bin/true
mount -w /app && /usr/bin/true

echo ">> Unpack the tarball with the various components."
tar xf /mnt/FILES.TGZ -C /

echo ">> Install all Ruby gems (this can take a while)"
gem install -l -N --ignore-dependencies /app/tmp/*.gem

echo ">> Install the gps_time package."
(cd /app/tmp/gps_time && make install && cp start.rc /cfg/rc.d/gps_time)

echo ">> Install and configure Redis."
mkdir -p /app/redis
chown redis:redis /app/redis
/usr/local/etc/rc.d/redis restart
redis-cli -i 1 info | grep -e ^redis_version -e uptime
ruby -r sgslib -e SGS::Config.configure_all

#
# Tweak some of the configuration parameters
echo ">> Set the system configuration parameters."
redis-cli set sgs_config.mission_file "/app/mission.yaml"
redis-cli set sgs_config.mission_state "0"
redis-cli set sgs_config.otto_device "/dev/ttyu0"
redis-cli set sgs_config.gps_device "/dev/ttyu1"
redis-cli set sgs_config.comm_device "/dev/ttyu2"
redis-cli set sgs_config.comm_speed "9600"
redis-cli set sgs_config.gps_speed "4800"
redis-cli set sgs_config.otto_speed "9600"

#
# Force-start a mission
ruby -r sgslib -e 'SGS::MissionStatus.new.start_test!'

echo ">> Clean up after configuration/installation."
rm -rf /app/tmp/gps_time
pkg delete -y perl5 dejagnu expect gettext-tools tcl86 gmake autoconf autoconf-wrapper automake

echo ">> Clean up filesystems"
mkdir -p /cfg/ssh
cp /etc/ssh/ssh_host_* /cfg/ssh

mv /cfg/device.hints /boot
chown root:wheel /boot/device.hints
chmod 444 /boot/device.hints

echo ">> Operation completed successfully!"
exit 0
