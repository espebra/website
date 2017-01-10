+++
Categories = ["netbooting"]
Description = ""
Tags = ["diskless", "el6", "ipxe", "linux", "netboot"]
date = "2013-03-21T09:57:00+01:00"
menu = "blog"
title = "CentOS/RHEL/SL 6: root filesystem on tmpfs, UPDATE"
aliases = [
        "/post/el6-rootfs-on-tmpfs-update2/"
]

+++

In EL6.4, the file ``/usr/share/dracut/modules.d/90dmsquash-live/dmsquash-live-root`` was updated so that the [previous patch](/post/el6-rootfs-on-tmpfs) no longer works as it should. I’ve updated the patch, and here it is:

``` diff
--- original    2013-03-20 16:25:23.698846581 +0100
+++ new 2013-03-21 08:58:11.175339694 +0100
@@ -24,6 +24,8 @@
 getarg readonly_overlay && readonly_overlay="--readonly" || readonly_overlay=""
 overlay=$(getarg overlay)
 
+getarg toram && toram="yes"
+
 # FIXME: we need to be able to hide the plymouth splash for the check really
 [ -e $livedev ] & fs=$(blkid -s TYPE -o value $livedev)
 if [ "$fs" = "iso9660" -o "$fs" = "udf" ]; then
@@ -132,7 +134,10 @@
     BASE_LOOPDEV=$( losetup -f )
     losetup -r $BASE_LOOPDEV $EXT3FS
 
-    do_live_from_base_loop
+    # Create overlay only if toram is not set
+    if [ -z "$toram" ] ; then
+        do_live_from_base_loop
+    fi
 fi
 
 # we might have an embedded ext3 on squashfs to use as rootfs (compressed live)
@@ -163,13 +168,66 @@
 
     umount -l /squashfs
 
-    do_live_from_base_loop
+    # Create overlay only if toram is not set
+    if [ -z "$toram" ] ; then
+        do_live_from_base_loop
+    fi
+fi
+
+# If the kernel parameter toram is set, create a tmpfs device and copy the 
+# filesystem to it. Continue the boot process with this tmpfs device as
+# a writable root device.
+if [ -n "$toram" ] ; then
+    blocks=$( blockdev --getsz $BASE_LOOPDEV )
+
+    echo "Create tmpfs ($blocks blocks) for the root filesystem..."
+    mkdir -p /image
+    mount -n -t tmpfs -o nr_blocks=$blocks tmpfs /image
+
+    echo "Copy filesystem image to tmpfs... (this may take a few minutes)"
+    dd if=$BASE_LOOPDEV of=/image/rootfs.img
+
+    ROOTFS_LOOPDEV=$( losetup -f )
+    echo "Create loop device for the root filesystem: $ROOTFS_LOOPDEV"
+    losetup $ROOTFS_LOOPDEV /image/rootfs.img
+
+    echo "It's time to clean up.. "
+
+    echo " > Umounting images"
+    umount -l /image
+    umount -l /dev/.initramfs/live
+
+    echo " > Detach $OSMIN_LOOPDEV"
+    losetup -d $OSMIN_LOOPDEV
+
+    echo " > Detach $OSMIN_SQUASHED_LOOPDEV"
+    losetup -d $OSMIN_SQUASHED_LOOPDEV
+    
+    echo " > Detach $BASE_LOOPDEV"
+    losetup -d $BASE_LOOPDEV
+    
+    echo " > Detach $SQUASHED_LOOPDEV"
+    losetup -d $SQUASHED_LOOPDEV
+    
+    echo " > Detach /dev/loop0"
+    losetup -d /dev/loop0
+
+    losetup -a
+
+    echo "Root filesystem is now on $ROOTFS_LOOPDEV."
+    echo
+
+    ln -s $ROOTFS_LOOPDEV /dev/root
+    printf '/bin/mount -o rw %s %s\n' "$ROOTFS_LOOPDEV" "$NEWROOT" > /mount/01-$$-live.sh
+    exit 0
 fi
 
 if [ -b "$OSMIN_LOOPDEV" ]; then
     # set up the devicemapper snapshot device, which will merge
     # the normal live fs image, and the delta, into a minimzied fs image
-    echo "0 $( blockdev --getsz $BASE_LOOPDEV ) snapshot $BASE_LOOPDEV $OSMIN_LOOPDEV p 8" | dmsetup create --readonly live-osimg-min
+    if [ -z "$toram" ] ; then
+        echo "0 $( blockdev --getsz $BASE_LOOPDEV ) snapshot $BASE_LOOPDEV $OSMIN_LOOPDEV p 8" | dmsetup create --readonly live-osimg-min
+    fi
 fi
 
 ROOTFLAGS="$(getarg rootflags)"
```

It may be easier to download it from [here](/files/patch.sl64.txt).

