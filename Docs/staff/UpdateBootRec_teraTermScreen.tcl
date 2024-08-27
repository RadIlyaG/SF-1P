
user>
user>
user>
user>su
password>****



SF-1p# logon debug
Key code:                    4784677249
password>**********
SF-1p#
SF-1p#
SF-1p#
SF-1p# debug shell/bin/stty: standard input: unable to perform all requested ope                                rations
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#




[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# fdisk
Usage:
 fdisk [options] <disk>    change partition table
 fdisk [options] -l <disk> list partition table(s)
 fdisk -s <partition>      give partition size(s) in blocks

Options:
 -b <size>             sector size (512, 1024, 2048 or 4096)
 -c[=<mode>]           compatible mode: 'dos' or 'nondos' (default)
 -h                    print this help text
 -u[=<unit>]           display units: 'cylinders' or 'sectors' (default)
 -v                    print program version
 -C <number>           specify the number of cylinders
 -H <number>           specify the number of heads
 -S <number>           specify the number of sectors per track

[root@localhost /]# fdisk -l

Disk /dev/mmcblk0: 31.3 GB, 31293702144 bytes, 61120512 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disk label type: dos
Disk identifier: 0xb148ffca

        Device Boot      Start         End      Blocks   Id  System
/dev/mmcblk0p1            2048      196607       97280   83  Linux
/dev/mmcblk0p2          196608      976895      390144   83  Linux
/dev/mmcblk0p3          976896     7813119     3418112   83  Linux
/dev/mmcblk0p4         7813120    61120511    26653696    5  Extended
/dev/mmcblk0p5         7815168    61120511    26652672   83  Linux
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# mount /dev/mmcblk0p1 /mnt/
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# cd /mnt/
[root@localhost mnt]# ls
bin   dev  lib    libexec  lost+found  mnt  proc  run   selinux  tmp  var
boot  etc  lib64  linuxrc  media       opt  root  sbin  sys      usr
[root@localhost mnt]#
[root@localhost mnt]#
[root@localhost mnt]#
[root@localhost mnt]# ls /
app   corefiles  fcontext        lib         media  proc  sbin  tmp     var
bin   dev        home            lib64       mnt    root  srv   USERFS
boot  etc        INITIAL_BUFFER  lost+found  opt    run   sys   usr
[root@localhost mnt]#
[root@localhost mnt]#
[root@localhost mnt]#
[root@localhost mnt]#
[root@localhost mnt]# cd /
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# ls
app   corefiles  fcontext        lib         media  proc  sbin  tmp     var
bin   dev        home            lib64       mnt    root  srv   USERFS
boot  etc        INITIAL_BUFFER  lost+found  opt    run   sys   usr
[root@localhost /]# uname -a
Linux localhost 4.19.128 #1 SMP PREEMPT Thu Aug 24 09:01:28 IDT 2023 aarch64 aarch64 aarch6                     4 GNU/Linux
[root@localhost /]# ls /mnt/
bin   dev  lib    libexec  lost+found  mnt  proc  run   selinux  tmp  var
boot  etc  lib64  linuxrc  media       opt  root  sbin  sys      usr
[root@localhost /]# ls /mnt/mnt/
[root@localhost /]# cd /mnt/
[root@localhost mnt]# ls
bin   dev  lib    libexec  lost+found  mnt  proc  run   selinux  tmp  var
boot  etc  lib64  linuxrc  media       opt  root  sbin  sys      usr
[root@localhost mnt]# cd etc/init
init.d/  inittab
[root@localhost mnt]# cd etc/init
init.d/  inittab
[root@localhost mnt]# cd etc/init
init.d/  inittab
[root@localhost mnt]# cd etc/init.d/
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost mnt]# cd etc/init.d/
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost mnt]# cd etc/init.d/
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost mnt]# cd etc/init.d/
[root@localhost init.d]# cat S90SoftwareUpgrade
#!/bin/bash

BOOT_ARGS=$(cat /proc/cmdline)
NFS_TYPE='pure_nfs'
if [[ "$BOOT_ARGS" == *"$NFS_TYPE"* ]]; then
  exit 0
fi

SW_BANK="/dev/mmcblk0p3"
ROOTFS="/dev/mmcblk0p5"

mount "$SW_BANK" /media > /dev/null

if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
        version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
        version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
else
        echo "no sw_pack_verion.txt indicator"
        echo "5" > /media/sw/sw_pack/bootIndex.txt;
        reboot -f;
fi;

echo "Performing upgrade to software pack ${version_name}"
mount "$ROOTFS" /mnt > /dev/null
echo "Cleaning rootfs"
rm -rf /mnt/*;

echo "Extracting software..."
tar --xattrs-include=security.capability --selinux -xzf /media/sw/sw_pack/${version} -C /mn                     t -m;
sync;

nfs_pt_flag="/media/nfs_pt1"
vcpe_ver=$(cat /media/sw/sw_info)
if [[ "$vcpe_ver" == *"6."* && -e "$nfs_pt_flag" ]]; then
        fstab_ver=/mnt/etc/fstab_6.0_8g
        if [ -e /media/flash_32 ]; then
                fstab_ver=/mnt/etc/fstab_6.0_32g
        fi
else
        fstab_ver=/mnt/etc/fstab_5.2
fi
if [ -f $fstab_ver ]; then
        rm -f /mnt/etc/fstab;
        mv $fstab_ver /mnt/etc/fstab;
fi
sync;

umount /mnt;

echo "Done extracting"
echo "5" > /media/sw/sw_pack/bootIndex.txt;
sync;
umount /media

echo "Software upgrade complete rebooting..."
reboot -f;
[root@localhost init.d]#
[root@localhost init.d]#
[root@localhost init.d]#
[root@localhost init.d]# cat S90SoftwareUpgrade
#!/bin/bash

BOOT_ARGS=$(cat /proc/cmdline)
NFS_TYPE='pure_nfs'
if [[ "$BOOT_ARGS" == *"$NFS_TYPE"* ]]; then
  exit 0
fi

SW_BANK="/dev/mmcblk0p3"
ROOTFS="/dev/mmcblk0p5"

mount "$SW_BANK" /media > /dev/null

if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
        version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
        version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
else
        echo "no sw_pack_verion.txt indicator"
        echo "5" > /media/sw/sw_pack/bootIndex.txt;
        reboot -f;
fi;

echo "Performing upgrade to software pack ${version_name}"
mount "$ROOTFS" /mnt > /dev/null
echo "Cleaning rootfs"
rm -rf /mnt/*;

echo "Extracting software..."
tar --xattrs-include=security.capability --selinux -xzf /media/sw/sw_pack/${version} -C /mnt -m;
sync;

nfs_pt_flag="/media/nfs_pt1"
vcpe_ver=$(cat /media/sw/sw_info)
if [[ "$vcpe_ver" == *"6."* && -e "$nfs_pt_flag" ]]; then
        fstab_ver=/mnt/etc/fstab_6.0_8g
        if [ -e /media/flash_32 ]; then
                fstab_ver=/mnt/etc/fstab_6.0_32g
        fi
else
        fstab_ver=/mnt/etc/fstab_5.2
fi
if [ -f $fstab_ver ]; then
        rm -f /mnt/etc/fstab;
        mv $fstab_ver /mnt/etc/fstab;
fi
sync;

umount /mnt;

echo "Done extracting"
echo "5" > /media/sw/sw_pack/bootIndex.txt;
sync;
umount /media

echo "Software upgrade complete rebooting..."
reboot -f;
[root@localhost init.d]# cat > S90SoftwareUpgrade
Ilya
^Z
[1]+  Stopped                 cat > S90SoftwareUpgrade
[root@localhost init.d]#
[root@localhost init.d]#
[root@localhost init.d]#
[root@localhost init.d]# cat S90SoftwareUpgrade
Ilya
[root@localhost init.d]#
[root@localhost init.d]#
[root@localhost init.d]#
[root@localhost init.d]# umount
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost init.d]# umount
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost init.d]# cd /
[root@localhost /]# umount

Usage:
 umount [-hV]
 umount -a [options]
 umount [options] <source> | <directory>

Options:
 -a, --all               unmount all filesystems
 -A, --all-targets       unmount all mountpoins for the given device
                         in the current namespace
 -c, --no-canonicalize   don't canonicalize paths
 -d, --detach-loop       if mounted loop device, also free this loop device
     --fake              dry run; skip the umount(2) syscall
 -f, --force             force unmount (in case of an unreachable NFS system)
 -i, --internal-only     don't call the umount.<type> helpers
 -n, --no-mtab           don't write to /etc/mtab
 -l, --lazy              detach the filesystem now, and cleanup all later
 -O, --test-opts <list>  limit the set of filesystems (use with -a)
 -R, --recursive         recursively unmount a target with all its children
 -r, --read-only         In case unmounting fails, try to remount read-only
 -t, --types <list>      limit the set of filesystem types
 -v, --verbose           say what is being done

 -h, --help     display this help and exit
 -V, --version  output version information and exit

For more details see umount(8).
[root@localhost /]# umount /mnt/
umount: /mnt: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@localhost /]# cd /
[root@localhost /]# umount /mnt/
umount: /mnt: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@localhost /]# mount /dev/mmcblk0p1 /mnt/
mount: /dev/mmcblk0p1 is already mounted or /mnt busy
       /dev/mmcblk0p1 is already mounted on /mnt
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# ps -aux | grep cat
dnfv      4895  0.3  2.9 248052 59280 ?        Ssl  00:00   0:16 python3 /home/dnfv/port_notification_starter.py
root      6070  0.0  0.0 105724   388 ttyMV0   T    01:09   0:00 cat
root      6133  0.0  0.0 106176  1824 ttyMV0   R+   01:16   0:00 grep --color=auto cat
[root@localhost /]# cd /home/
[root@localhost home]# umount /mnt/
umount: /mnt: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@localhost home]# ps -aux | grep mnt
root      6140  0.0  0.0 106176  1756 ttyMV0   R+   01:16   0:00 grep --color=auto mnt
[root@localhost home]# cd /mnt/
[root@localhost mnt]# ls
bin   dev  lib    libexec  lost+found  mnt  proc  run   selinux  tmp  var
boot  etc  lib64  linuxrc  media       opt  root  sbin  sys      usr
[root@localhost mnt]# nano etc/
bind/          group          localtime      passwd         shadow
bind.keys      hostname       mke2fs.conf    profile        shells
cron.d/        hosts          mtab           profile.d/     ssl/
dbus-1/        init.d/        network/       protocols      timezone
e2scrub.conf   inittab        nsswitch.conf  resolv.conf    xattr.conf
environment    inputrc        os-release     security/
fstab          issue          pam.d/         services
[root@localhost mnt]# nano etc/
bind/          group          localtime      passwd         shadow
bind.keys      hostname       mke2fs.conf    profile        shells
cron.d/        hosts          mtab           profile.d/     ssl/
dbus-1/        init.d/        network/       protocols      timezone
e2scrub.conf   inittab        nsswitch.conf  resolv.conf    xattr.conf
environment    inputrc        os-release     security/
fstab          issue          pam.d/         services
[root@localhost mnt]# nano etc/
bind/          group          localtime      passwd         shadow
bind.keys      hostname       mke2fs.conf    profile        shells
cron.d/        hosts          mtab           profile.d/     ssl/
dbus-1/        init.d/        network/       protocols      timezone
e2scrub.conf   inittab        nsswitch.conf  resolv.conf    xattr.conf
environment    inputrc        os-release     security/
fstab          issue          pam.d/         services
[root@localhost mnt]# nano etc/init
init.d/  inittab
[root@localhost mnt]# nano etc/init
init.d/  inittab
[root@localhost mnt]# nano etc/init.d/
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost mnt]# nano etc/init.d/
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost mnt]# nano etc/init.d/
rcK                 S02klogd            S30dbus
rcS                 S02sysctl           S40network
S01syslogd          S20urandom          S90SoftwareUpgrade
[root@localhost mnt]# nano etc/init.d/S90SoftwareUpgrade
bin/        lib/        lost+found/ proc/       selinux/    var/
boot/       lib64/      media/      root/       sys/
dev/        libexec/    mnt/        run/        tmp/
etc/        linuxrc     opt/        sbin/       usr/
[root@localhost mnt]# nano etc/init.d/S90SoftwareUpgrade
bin/        lib/        lost+found/ proc/       selinux/    var/
boot/       lib64/      media/      root/       sys/
dev/        libexec/    mnt/        run/        tmp/
etc/        linuxrc     opt/        sbin/       usr/
[root@localhost mnt]# nano etc/init.d/S90SoftwareUpgrade

  GNU nano 2.3.1       File: etc/init.d/S90SoftwareUpgrade

Ilya


















                                [ Read 1 line ]

[root@localhost mnt]#
[root@localhost mnt]#
[root@localhost mnt]# cd /
[root@localhost /]# sync
[root@localhost /]# umount /mnt/
umount: /mnt: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@localhost /]# ps -aux | grep mnt
root      6159  0.0  0.0 106176  1816 ttyMV0   R+   01:18   0:00 grep --color=auto mnt
[root@localhost /]# umount -f /mnt/
umount: /mnt: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@localhost /]# lsof
bash: lsof: command not found
[root@localhost /]# umount -f /mnt
umount: /mnt: target is busy.
        (In some cases useful info about processes that use
         the device is found by lsof(8) or fuser(1))
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# ps -aux | grep cat
dnfv      4895  0.3  2.9 248052 59280 ?        Ssl  00:00   0:16 python3 /home/dnfv/port_notification_starter.py
root      6070  0.0  0.0 105724   388 ttyMV0   T    01:09   0:00 cat
root      6205  0.0  0.0 106176  1836 ttyMV0   R+   01:23   0:00 grep --color=auto cat
[root@localhost /]# kill -9 6070
[root@localhost /]#
[1]+  Killed                  cat > S90SoftwareUpgrade  (wd: /mnt/etc/init.d)
(wd now: /)
[root@localhost /]#
[root@localhost /]# ls
app   corefiles  fcontext        lib         media  proc  sbin  tmp     var
bin   dev        home            lib64       mnt    root  srv   USERFS
boot  etc        INITIAL_BUFFER  lost+found  opt    run   sys   usr
[root@localhost /]# cd /
[root@localhost /]# umount -f /mnt
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# exit
exit

SF-1p#
SF-1p#
SF-1p#
SF-1p#
SF-1p# \debug shell /bin/stty: standard input: unable to perform all requested operations
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# mount /dev/mmcblk0p1 /mnt/
[root@localhost /]# cat > /mnt/etc/init.d/S90SoftwareUpgrade
#!/bin/bash

BOOT_ARGS=$(cat /proc/cmdline)
NFS_TYPE='pure_nfs'
if [[ "$BOOT_ARGS" == *"$NFS_TYPE"* ]]; then
  exit 0
fi

SW_BANK="/dev/mmcblk0p3"
ROOTFS="/dev/mmcblk0p5"

mount "$SW_BANK" /media > /dev/null

if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
        version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
        version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
else
        echo "no sw_pack_verion.txt indicator"
        echo "5" > /media/sw/sw_pack/bootIndex.txt;
        reboot -f;
fi;

echo "Performing upgrade to software pack ${version_name}"
mount "$ROOTFS" /mnt > /dev/null
echo "Cleaning rootfs"
rm -rf /mnt/*;

echo "Extracting software..."
tar --xattrs-include=security.capability --selinux -xzf /media/sw/sw_pack/${version} -C /mnt -m;
sync;

nfs_pt_flag="/media/nfs_pt1"
vcpe_ver=$(cat /media/sw/sw_info)
if [[ "$vcpe_ver" == *"6."* && -e "$nfs_pt_flag" ]]; then
        fstab_ver=/mnt/etc/fstab_6.0_8g
        if [ -e /media/flash_32 ]; then
                fstab_ver=/mnt/etc/fstab_6.0_32g
        fi
else
        fstab_ver=/mnt/etc/fstab_5.2
fi
if [ -f $fstab_ver ]; then
        rm -f /mnt/etc/fstab;
        mv $fstab_ver /mnt/etc/fstab;
fi
sync;

umount /mnt;

echo "Done extracting"
echo "5" > /media/sw/sw_pack/bootIndex.txt;
sync;
umount /media

echo "Software upgrade complete rebooting..."
reboot -f;
^C


^Z
[1]+  Stopped                 cat > /mnt/etc/init.d/S90SoftwareUpgrade
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# nano /mnt/etc/init.d/S90SoftwareUpgrade


















  GNU nano 2.3.1      File: /mnt/etc/init.d/S90SoftwareUpgrade

#!/bin/bash

BOOT_ARGS=$(cat /proc/cmdline)
NFS_TYPE='pure_nfs'
if [[ "$BOOT_ARGS" == *"$NFS_TYPE"* ]]; then
  exit 0
fi

SW_BANK="/dev/mmcblk0p3"
ROOTFS="/dev/mmcblk0p5"

mount "$SW_BANK" /media > /dev/null

if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
        version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
        version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
else
        echo "no sw_pack_verion.txt indicator"
        echo "5" > /media/sw/sw_pack/bootIndex.txt;
                               [ Wrote 59 lines ]

[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# nano /mnt/etc/init.d/S90SoftwareUpgrade


















  GNU nano 2.3.1      File: /mnt/etc/init.d/S90SoftwareUpgrade

#!/bin/bash

BOOT_ARGS=$(cat /proc/cmdline)
NFS_TYPE='pure_nfs'
if [[ "$BOOT_ARGS" == *"$NFS_TYPE"* ]]; then
  exit 0
fi

SW_BANK="/dev/mmcblk0p3"
ROOTFS="/dev/mmcblk0p5"

mount "$SW_BANK" /media > /dev/null

if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
        version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
        version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
else
        echo "no sw_pack_verion.txt indicator"
        echo "5" > /media/sw/sw_pack/bootIndex.txt;
                               [ Read 59 lines ]

[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# nano /mnt/etc/init.d/S90SoftwareUpgrade^C
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# ps -aux | grep cat
dnfv      4895  0.3  2.9 248052 59280 ?        Ssl  00:00   0:16 python3 /home/dnfv/port_notification_starter.py
root      6237  0.0  0.0 105724   368 ttyMV0   T    01:25   0:00 cat
root      6271  0.0  0.0 106176  1860 ttyMV0   R+   01:29   0:00 grep --color=auto cat
[root@localhost /]# kill -9 6237
[root@localhost /]#
[1]+  Killed                  cat > /mnt/etc/init.d/S90SoftwareUpgrade
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# > /mnt/etc/init.d/S90SoftwareUpgrade
[root@localhost /]# car /mnt/etc/init.d/S90SoftwareUpgrade
bash: car: command not found
[root@localhost /]# cat /mnt/etc/init.d/S90SoftwareUpgrade
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# > /mnt/etc/init.d/S90SoftwareUpgrade
[root@localhost /]# nano /mnt/etc/init.d/S90SoftwareUpgrade


















  GNU nano 2.3.1      File: /mnt/etc/init.d/S90SoftwareUpgrade

fi
if [ -f $fstab_ver ]; then
        rm -f /mnt/etc/fstab;
        mv $fstab_ver /mnt/etc/fstab;
fi
sync;

umount /mnt;

echo "Done extracting"
echo "5" > /media/sw/sw_pack/bootIndex.txt;
sync;
umount /media

echo "Software upgrade complete rebooting..."
reboot -f;



                               [ Wrote 57 lines ]

[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# umount /mnt/
[root@localhost /]# cat /mnt/etc/init.d/S90SoftwareUpgrade
cat: /mnt/etc/init.d/S90SoftwareUpgrade: No such file or directory
[root@localhost /]# mount /dev/mmcblk0p1 /mnt/
[root@localhost /]# cat /mnt/etc/init.d/S90SoftwareUpgrade
#!/bin/bash

BOOT_ARGS=$(cat /proc/cmdline)
NFS_TYPE='pure_nfs'
if [[ "$BOOT_ARGS" == *"$NFS_TYPE"* ]]; then
  exit 0
fi

SW_BANK="/dev/mmcblk0p3"
ROOTFS="/dev/mmcblk0p5"

mount "$SW_BANK" /media > /dev/null

if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
        version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
        version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
else
        echo "no sw_pack_verion.txt indicator"
        echo "5" > /media/sw/sw_pack/bootIndex.txt;
        reboot -f;
fi;

echo "Performing upgrade to software pack ${version_name}"
mount "$ROOTFS" /mnt > /dev/null
echo "Cleaning rootfs"
rm -rf /mnt/*;

echo "Extracting software..."
tar --xattrs-include=security.capability --selinux -xzf /media/sw/sw_pack/${version} -C /mnt -m;
sync;

nfs_pt_flag="/media/nfs_pt1"
vcpe_ver=$(cat /media/sw/sw_info)
if [[ "$vcpe_ver" == *"6."* && -e "$nfs_pt_flag" ]]; then
        fstab_ver=/mnt/etc/fstab_6.0_8g
        if [ -e /media/flash_32 ]; then
                fstab_ver=/mnt/etc/fstab_6.0_32g
        fi
else
        fstab_ver=/mnt/etc/fstab_5.2
fi
if [ -f $fstab_ver ]; then
        rm -f /mnt/etc/fstab;
        mv $fstab_ver /mnt/etc/fstab;
fi
sync;

umount /mnt;

echo "Done extracting"
echo "5" > /media/sw/sw_pack/bootIndex.txt;
sync;
umount /media

echo "Software upgrade complete rebooting..."
reboot -f;

[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# exit
exit

SF-1p# \debug shell /bin/stty: standard input: unable to perform all requested operations
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]#
[root@localhost /]# umount /mnt/
[root@localhost /]# umount /mnt/
umount: /mnt/: not mounted
[root@localhost /]# exit
exit

SF-1p#
SF-1p#
SF-1p# info
    configure
        echo "Terminal Configuration"
#       Terminal Configuration
        terminal
            timeout forever
            console-timeout forever
        exit
        echo "Management configuration"
#       Management configuration
        management
            login-user "netconf-su"
                shutdown
            exit
            echo "SNMP Configuration"
#           SNMP Configuration
            snmp
                snmp-engine-id mac 18-06-F5-87-20-32
            exit
        exit
        echo "Port Configuration"
#       Port Configuration
        port
            ethernet 6
                no shutdown
            exit
        exit
        router 1
            name "Router#1"
            interface 32
                address 169.254.1.1/16
                bind ethernet 6
                no shutdown
            exit
        exit
    exit



SF-1p# configure router 1
SF-1p>config>router(1)# interface 32
SF-1p>config>router(1)>interface(32)# shutdown
SF-1p>config>router(1)>interface(32)# exit
SF-1p>config>router(1)# no interface 32
SF-1p>config>router(1)# interface 32
SF-1p>config>router(1)>interface(32)$ dhc
dhcp
dhcp-client
dhcpv6-client
dhcpv6-server
SF-1p>config>router(1)>interface(32)$ dhcp
SF-1p>config>router(1)>interface(32)$ bind ethernet 6
SF-1p>config>router(1)>interface(32)$ no shutdown
SF-1p>config>router(1)>interface(32)$
SF-1p>config>router(1)>interface(32)$
SF-1p>config>router(1)>interface(32)$
SF-1p>config>router(1)>interface(32)$ show status

Admin:Up          Oper: Up

Ip Addresses:


IPv4 Default Router : 172.18.93.1

DHCP Client Information

DHCP Status : Waiting for Lease

SF-1p>config>router(1)>interface(32)$ show status

Admin:Up          Oper: Up

Ip Addresses:


IPv4 Default Router : 172.18.93.1

DHCP Client Information

DHCP Status : Waiting for Lease

SF-1p>config>router(1)>interface(32)$ show status

Admin:Up          Oper: Up

Ip Addresses:

  172.18.93.76/24                             (dhcp)          (preferred)

IPv4 Default Router : 172.18.93.1

DHCP Client Information

DHCP Status : Holding Lease

Server         : 192.114.24.10
Router         : 172.18.93.1
Lease Obtained : 2023-12-11 1:41:47
Expires        : 2024-01-10 1:41:47
Lease Renewal: : 2023-12-26 1:41:47
Rebinding:     : 2024-01-06 7:41:47
DNS Server     : 192.168.110.110; 192.114.24.169
Domain Name    : --
TFTP Server    : --
Bootfile Name  : --

Static Routes : --                                                                                                                                                                                                              

SF-1p>config>router(1)>interface(32)$
SF-1p>config>router(1)>interface(32)$ exit
SF-1p>config>router(1)# exit
SF-1p>config# save
SF-1p>config#
SF-1p>config#
SF-1p>config#
*****running-config copied to startup-config successfully*****
*****796 bytes copied in 1 secs (796 bytes/sec)*****

SF-1p>config#
SF-1p>config#
SF-1p>config# exit
SF-1p# file
SF-1p>file# show sw-pack
Name           Version      Creation Time          Actual
-----------------------------------------------------------------------------
sw-pack-1      5.4.0.139.28 2023-12-11   10:11:00  active

SF-1p>file# exit
SF-1p#
SF-1p#
SF-1p#
SF-1p#
SF-1p#
SF-1p# if [ -f '/media/sw/sw_pack/sw-pack_version.txt' ]; then
#       ^
# cli error: command not recognized
SF-1p#         version=$(sed '1q;d' /media/sw/sw_pack/sw-pack_version.txt);
#              ^
# cli error: command not recognized
SF-1p#         version_name=$(sed '2q;d' /media/sw/sw_pack/sw-pack_version.txt);
#              ^
# cli error: command not recognized
SF-1p# ping 172.18.92.89

Reply from 172.18.92.89: bytes = 32, packet number = 0, time <= 24 ms
Reply from 172.18.92.89: bytes = 32, packet number = 1, time <= 16 ms
Ping is terminated by user.

SF-1p# copy sftp://secflow:123456@172.18.92.89/vcpeos_6.2.0.81_arm.tar.gz sw-pack-2
 Are you sure? [yes/no] _ y
*****! Starting file transfer...*****

SF-1p#
SF-1p# file
SF-1p>file# show copy
Network to Device, Transferring Data
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:0 bytes in:6 secs(0 bytes/sec)


SF-1p>file# show copy
Network to Device, Transferring Data
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:0 bytes in:9 secs(0 bytes/sec)


SF-1p>file# show copy
Network to Device, Transferring Data
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:0 bytes in:10 secs(0 bytes/sec)


SF-1p>file# show copy
Network to Device, Transferring Data
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:0 bytes in:11 secs(0 bytes/sec)


SF-1p>file# show copy
Network to Device, Transferring Data
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:0 bytes in:14 secs(0 bytes/sec)


SF-1p>file# show copy
Network to Device, Transferring Data
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:15955248 bytes in:15 secs(1063683 bytes/sec)


SF-1p>file# exit
SF-1p# admin software install sw
sw-pack-1
sw-pack-2
sw-update-1
sw-update-2
SF-1p# admin software install sw-p
sw-pack-1
sw-pack-2
SF-1p# file
SF-1p>file# show copy
Network to Device, Extracting File
Src: sftp://.../vcpeos_6.2.0.81_arm.tar.gz
Dst: sw-pack-2
Started: 2023-12-11 01:44:13
Transferred:884094874 bytes in:447 secs(1977840 bytes/sec)


SF-1p>file#
*****sftp://.../vcpeos_6.2.0.81_arm.tar.gz copied to sw-pack-2 successfully*****
*****884094874 bytes copied in 552 secs (1601621 bytes/sec)*****

SF-1p>file#exit all
SF-1p# admin software install sw-pack-2
 ! Device will install file and reboot. Are you sure? [yes/no] _ y
SF-1p#
*****startup-config copied to restore-point-config successfully*****
*****796 bytes copied in 1 secs (796 bytes/sec)*****

SF-1p#
--------Device reboot----------

[ 7052.629�


root@localhost:/# cat /boot/content.txt
Image - vcpeos_6.2.0.81_arm
kernel - kernel_4.19.128.40
rados - RADOS_8.10.0.52
secflow - VCPESF_5.0.1.007



proc S90_Software_Upgrade {} {
  package require RLEH
  package require RLCom
  global gaSet
  set ::sendSlow 0
  catch {RLEH::Close}
  
  RLEH::Open
  set com $gaSet(comDut)
  set ret [RLCom::Open $com 115200 8 NONE 1]
  Send $com "\r" stam 0.25
  #catch {RLCom::Close $com}
  
  clipboard clear
  update idletasks
  clipboard append "fdisk -l\r"
  update idletasks
  Send $com [clipboard get] stam 0.25
  clipboard clear
  update idletasks
  
  set s90su  C:/MyDocuments/ate/AutoTesters/TCL/SF-1P/Docs/staff/S90SoftwareUpgrade.txt
  if [catch {open $s90su r} id] {
    puts $id
	  return -1
  } else {
    set lines [read $id]
	  close $id
  }
  
  clipboard append $lines
  Send $com "mount /dev/mmcblk0p1 /mnt/\r" stam 0.25
  Send $com "cat /mnt/etc/init.d/S90SoftwareUpgrade1\r" stam 0.25
  Send $com "> /mnt/etc/init.d/S90softwareupgrade1\r" stam 0.25
  Send $com "cat /mnt/etc/init.d/S90SoftwareUpgrade1\r" stam 0.25
#  Send $com "echo [clipboard get] > /mnt/etc/init.d/S90SoftwareUpgrade \r" stam 0.25
 # Send $com "echo $lines > /mnt/etc/init.d/S90SoftwareUpgrade1 \r" stam 0.25
  Send $com "nano /mnt/etc/init.d/S90SoftwareUpgrade1\r" stam 0.25
  Send $com "$lines\r" stam 0.25
  #Send $com "[clipboard get]\r" stam 0.25
  Send $com \30 stam 0.25
  Send $com y\r stam 0.25
  Send $com "cat /mnt/etc/init.d/S90SoftwareUpgrade1\r" stam 0.25
  Send $com "umount /mnt/\r" stam 0.25
  Send $com "umount /mnt/\r" stam 0.25
  
  catch {RLCom::Close $gaSet(comDut)}
  catch {RLEH::Close}
  set ::lines $lines
  return 0
}


import serial
def S90_Software_Upgrade():
    ser = serial.Serial("COM1", 115200, 8, "N", 1, 0, 0, 2)
    ser.reset_input_buffer()
    ser.reset_output_buffer()
    rx = ''
    
    sent = '\r\r'
    ser.write(sent.encode())
    ser.flush()
    data_bytes = ser.in_waiting
    rx += ser.read(data_bytes).decode()
    print(f'rx:<{rx}>')
    ser.close()










