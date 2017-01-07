+++
Categories = ["netbooting"]
Tags = ["diskless", "el7", "ipxe", "linux", "netboot", "initramfs", "virt-builder"]
menu = "blog"
date = "2017-01-06T21:34:20+01:00"
title = "CentOS 7 root filesystem on tmpfs"
Description = ""

+++

Several years ago I wrote a [series](/post/el6-rootfs-on-tmpfs/) [of](/post/el6-rootfs-on-tmpfs-update/) [posts](/post/el6-rootfs-on-tmpfs-update2/) on how to run EL6 with its root filesystem on tmpfs. This post is a continuation of that series, and explains step by step how to run CentOS 7 with its root filesystem in memory. It should apply to RHEL, Ubuntu, Debian and other Linux distributions as well.

## Build environment

A build host is needed to prepare the image to boot from. The build host should run CentOS 7 x86\_64, and have the following packages installed:

``` bash
yum install libvirt virt-builder guestfish
```

Make sure the libvirt daemon is running:

``` bash
systemctl start libvirtd
```

Create some directories that will be used later, however feel free to relocate these to somewhere else:

``` bash
mkdir -p /work/initramfs/bin
mkdir -p /work/newroot
mkdir -p /work/result
```

## Disk image

For simplicity reasons we'll fetch our rootfs from a pre-built disk image, but it is possible to build a [custom disk image using virt-manager](https://www.redpill-linpro.com/sysadvent/2016/12/14/use-virt-manager-to-build-disk-images.html). I expect that most people would like to create their own disk image from scratch, but this is outside the scope of this post.

Use ``virt-builder`` to download a pre-built CentOS 7.3 disk image and set the root password:

``` bash
virt-builder centos-7.3 -o /work/disk.img --root-password password:changeme
```

Export the files from the disk image to one of the directories we created earlier:

``` bash
guestfish --ro -a /work/disk.img -i copy-out / /work/newroot/
```

Clear fstab since it contains mount entries that no longer apply:

``` bash
echo > /work/newroot/etc/fstab
```

SELinux will complain about incorrect disk label at boot, so let's just disable it right away. Production environments should have SELinux enabled.

``` bash
echo "SELINUX=disabled" > /work/newroot/etc/selinux/config
```

Disable clearing the screen on login failure to make it possible to read error messages:

``` bash
mkdir /work/newroot/etc/systemd/system/getty@.service.d
cat > /work/newroot/etc/systemd/system/getty@.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF
```

## Initramfs

We'll create our custom initramfs from scratch. The boot procedure will be, simply put:

1. Fetch kernel and a custom initramfs.
2. Execute kernel.
3. Mount the initramfs as the temporary root filesystem (for the kernel).
4. Execute ``/init`` (shipped in the initramfs).
5. Create a ``tmpfs`` mount point.
6. Extract the root filesystem to the ``tmpfs`` mount point.
7. Execute ``switch_root`` to boot on the ``tmpfs`` root filesystem.

The initramfs will be based on [BusyBox](https://www.busybox.net/). Download a pre-built binary or compile it from source, put the binary in the ``initramfs/bin`` directory. In this post I'll just download a pre-built binary:

``` bash
wget -O /work/initramfs/bin/busybox https://www.busybox.net/downloads/binaries/1.26.1-defconfig-multiarch/busybox-x86_64
```

Make sure that ``busybox`` has the execute bit set:

``` bash
chmod +x /work/initramfs/bin/busybox
```

Create the file ``/work/initramfs/init`` with the following contents:

``` bash
```

Create the root filesystem archive using ``tar``. The following command also uses xz compression to reduce the final size of the archive:

``` bash
cd /work/newroot
tar cJf /work/initramfs/rootfs.tar.xz .
```

Create ``initramfs.gz`` using:

``` bash
cd /work/initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > /work/result/initramfs.gz
```

Copy the kernel directly from the root filesystem using:

``` bash
cp /work/newroot/boot/vmlinuz-*x86_64 /work/result/vmlinuz
```

The ``/work/result`` directory now contains two files with file sizes similar to the following:

``` bash
ls -lh /work/result/
total 277M
-rw-r--r-- 1 root root 272M Jan  6 23:42 initramfs.gz
-rwxr-xr-x 1 root root 5.2M Jan  6 23:42 vmlinuz
```

These files can be loaded directly in GRUB from disk, or using [iPXE](http://ipxe.org/) over HTTP using a script similar to:

```
#!ipxe
kernel http://example.com/vmlinuz
initrd http://example.com/initramfs.gz
boot
```

Well done!
