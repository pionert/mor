#! /bin/bash

/etc/init.d/mysqld stop
/sbin/fuser -mu /dev/ram0
/bin/umount -l -v /dev/ram0
/bin/rm -fr /home/ramdisk
/sbin/mke2fs -m 0 /dev/ram0
/bin/mkdir -p /home/ramdisk
/bin/mount /dev/ram0 /home/ramdisk
/bin/cp -fr /var/lib/mysql /home/ramdisk
/bin/chmod -R 777 /home/ramdisk
/etc/init.d/mysqld start
