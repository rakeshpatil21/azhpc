#!/bin/bash

# fail on any error
set -e

HEADNODE=10.0.2.4

sed -i 's/^ResourceDisk.MountPoint=\/mnt\/resource$/ResourceDisk.MountPoint=\/mnt\/local_resource/g' /etc/waagent.conf
umount /mnt/resource

mkdir -p /mnt/resource/scratch

cat << EOF >> /etc/security/limits.conf
*               hard    memlock         unlimited
*               soft    memlock         unlimited
*               soft    nofile          65535
*               soft    nofile          65535
EOF

cat << EOF >> /etc/fstab
$HEADNODE:/home    /home   nfs defaults 0 0
$HEADNODE:/mnt/resource/scratch    /mnt/resource/scratch   nfs defaults 0 0
EOF

#yum --enablerepo=extras install -y -q epel-release
#yum install -y -q htop pdsh
yum install -y -q nfs-utils psmisc
setsebool -P use_nfs_home_dirs 1

mount -a

# Don't require password for HPC user sudo
echo "hpcuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
# Disable tty requirement for sudo
sed -i 's/^Defaults[ ]*requiretty/# Defaults requiretty/g' /etc/sudoers

for i in /proc/sys/kernel/sched_domain/cpu*/domain0
do
    echo "0" >${i}/idle_idx
    echo "4655" >${i}/flags
done

