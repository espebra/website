+++
Categories = ["netbooting"]
Tags = ["diskless", "el7", "ipxe", "linux", "netboot", "initramfs", "packer", "zfs"]
menu = "blog"
date = "2017-10-20T23:33:20+01:00"
title = "ZFS NAS using CentOS 7 from tmpfs"
Description = ""

+++

Following up on the [CentOS 7 root filesystem on tmpfs](/posts/centos-7-rootfs-on-tmpfs/) post, here comes a guide on how to run a ZFS enabled CentOS 7 NAS server (with the operating system) from tmpfs.

## Hardware

* HP ProLiant MicroServer
* HP ProLiant MicroServer Remote Access Card
* AMD Turion(tm) II Neo N54L Dual-Core Processor
* 2x 8 GB 1333 MHZ ECC memory modules
* 4x 4 TB SATA hard drives (HGST, Western Digital and Seagate)
* Built-in Broadcom Limited NetXtreme BCM5723 Gigabit Ethernet adapter

## Preparing the build environment

The disk image is built in macOS using [Packer](https://www.packer.io) and [VirtualBox](https://www.virtualbox.org/). Virtualbox is installed using the appropriate platform package that is downloaded from [their website](https://www.virtualbox.org/wiki/Downloads), and Packer is installed using brew:

```bash
$ brew install packer
```

## Building the disk image

Three files are needed in order to build the disk image; a Packer template file, an Anaconda kickstart file and a shell script that is used to configure the disk image after installation. The following files can be used as examples:

* [``template.json``](/files/template.json) (Packer template example file)
* [``ks.cfg``](/files/ks.cfg) (Anaconda kickstart example file)
* [``provision.sh``](/files/provision.sh) (Provision shell script example file)

Create some directories:

```bash
$ mkdir ~work/centos-7-zfs/
$ mkdir ~work/centos-7-zfs/http/
$ mkdir ~work/centos-7-zfs/scripts/
```

Copy the files to these directories:

```bash
$ cp template.json ~work/centos-7-zfs/
$ cp ks.cfg ~work/centos-7-zfs/http/
$ cp provision.sh ~work/centos-7-zfs/scripts/
```

Modify each of the files to fit your environment.

Start the build process using Packer:

```bash
$ cd ~work/centos-7-zfs/
$ packer build template.json
```

This will download the CentOS 7 ISO file, start an HTTP server to serve the kickstart file and start a virtual machine using Virtualbox:

![Packer installer screenshot](/img/packer-installer.png)

The virtual machine will boot into Anaconda and run through the installation process as specified in the kickstart file:

![Anaconda installer screenshot](/img/anaconda-installer.png)

When the installation process is complete, the disk image will be available in the ``output-virtualbox-iso`` folder with the [``vmdk``](https://en.wikipedia.org/wiki/VMDK) extension.

![Packer done screenshot](/img/packer-installer-done.png)

The disk image is now ready to be put in initramfs.

## Putting the disk image in initramfs

This section is quite similar to the previous blog post [CentOS 7 root filesystem on tmpfs](/posts/centos-7-rootfs-on-tmpfs/) but with minor differences. For simplicity reasons it is executed on a host running CentOS 7.

Create the build directories:

```bash
$ mkdir /work
$ mkdir /work/newroot
$ mkdir /work/result
```
 
Export the files from the disk image to one of the directories we created earlier:

```bash
$ export LIBGUESTFS_BACKEND=direct
$ guestfish --ro -a packer-virtualbox-iso-1508790384-disk001.vmdk -i copy-out / /work/newroot/
```

Modify ``/etc/fstab``:

```bash
$ cat > /work/newroot/etc/fstab << EOF
tmpfs       /         tmpfs    defaults,noatime 0 0
none        /dev      devtmpfs defaults         0 0
devpts      /dev/pts  devpts   gid=5,mode=620   0 0
tmpfs       /dev/shm  tmpfs    defaults         0 0
proc        /proc     proc     defaults         0 0
sysfs       /sys      sysfs    defaults         0 0
EOF
```

Disable selinux:

```bash
echo "SELINUX=disabled" > /work/newroot/etc/selinux/config
```

Disable clearing the screen on login failure to make it possible to read any error messages:

```bash
mkdir /work/newroot/etc/systemd/system/getty@.service.d
cat > /work/newroot/etc/systemd/system/getty@.service.d/noclear.conf << EOF
[Service]
TTYVTDisallocate=no
EOF
```

Now jump to the **Initramfs** and **Result** sections in the [CentOS 7 root filesystem on tmpfs](/posts/centos-7-rootfs-on-tmpfs/) and follow those steps until the end when the result is a ``vmlinuz`` and ``initramfs`` file.

## ZFS configuration

The first time the NAS server boots on the disk image, the ZFS storage pool and volumes will have to be configured. Refer to the [ZFS documentation](https://docs.oracle.com/cd/E19253-01/819-5461/gaynr/index.html) for information on how to do this, and use the following command only as guidelines.

Create the storage pool:

```bash
$ sudo zpool create data mirror sda sdb mirror sdc sdd
```

Create the volumes:

```bash
$ sudo zfs create data/documents
$ sudo zfs create data/games
$ sudo zfs create data/movies
$ sudo zfs create data/music
$ sudo zfs create data/pictures
$ sudo zfs create data/upload
```

Share some volumes using NFS:

```bash
zfs set sharenfs=on data/documents
zfs set sharenfs=on data/games
zfs set sharenfs=on data/music
zfs set sharenfs=on data/pictures
```

Print the storage pool status:

```bash
$ sudo zpool status
  pool: data
 state: ONLINE
  scan: scrub repaired 0B in 20h22m with 0 errors on Sun Oct  1 21:04:14 2017
config:

	NAME        STATE     READ WRITE CKSUM
	data        ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdd     ONLINE       0     0     0
	    sdc     ONLINE       0     0     0
	  mirror-1  ONLINE       0     0     0
	    sda     ONLINE       0     0     0
	    sdb     ONLINE       0     0     0

errors: No known data errors
```
