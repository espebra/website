+++
Categories = ["netbooting"]
Description = ""
Tags = ["diskless", "el6", "ipxe", "linux", "netboot"]
date = "2013-06-23T21:44:19+01:00"
menu = "blog"
title = "CentOS/RHEL/SL 6: root filesystem on tmpfs, UPDATE #2"
aliases = [
	"/post/el6-rootfs-on-tmpfs-update/"
]

+++


In a [previous post](/posts/el6-rootfs-on-tmpfs), I’ve explained how to boot EL6 from memory without having / needing a physical disk.

A bright reader, Jeff, came up with an alternative method. This alternative method does not involve dd’ing the image into a loop device, but instead copying the contents of the disk image directly into tmpfs. The result is higher write/read performance and generally lower memory requirements. The latter because unused disk space does not consume memory, which is important to consider when choosing the method to use in production systems.

## Example ##

I got a lot of questions by e-mail on the previous posts regarding the subject and how to actually getting it to work, so this time I’ve created a complete set of files to get you going with Jeff’s method:

* The original ``dmsquash-live-root``. You won’t need this, but I added it as a reference.
* The updated ``dmsquash-live-root``. You might need to look at this to understand what is going on.
* The patch which is the diff of the two previous files. This one is used in the kickstart file below as a base64 encoded string.
* The complete example kickstart file. This is a rather default CentOS 6.4 x86_64. The root password is being set to ‘foobar’.

## Build the disk image ##

``` bash
$ sudo yum install livecd-tools
$ sudo livecd-creator --config=centos64-pxe.ks --fslabel=centos64-pxe
$ sudo livecd-iso-to-pxeboot centos64-pxe.iso
```

The last command will output ``vmlinuz0`` and ``initrd0.img``. Put these on your webserver, http://example.com/.

## Boot a host on the disk image ##

Boot it using DHCP, iPXE and the following iPXE script:

``` bash
#!ipxe 
initrd http://example.com/initrd0.img
kernel http://example.com/vmlinuz0 initrd=/initrd0.img root=/centos64-pxe.iso rootfstype=auto rw liveimg toram size=4096
boot
```

Note the size boot parameter. The patch will set the tmpfs size (in MB) according to this parameter. If the parameter is not set, 2048 is used as a default. The size can be changed runtime using mount, for example:

``` bash
$ sudo mount -o remount,size=10G,rw /dev/root
```

## Difference in memory usage ##

The files in the file system in our example will consume around 1 GB of disk space. When booting with a file system (tmpfs) size of 4 GB, the memory usage is quite different between the previous and this (Jeff’s) method:

### Previous method ###

The important thing to notice here is that the file system already have allocated 4 GB of memory. This is because the file system already is consuming the amount of memory equivalent to the given size of the file system, independently on the actual disk space being consumed by the files currently in the file system.

``` bash
[root@lab-e ~]# free -m
             total       used       free     shared    buffers     cached
Mem:          7956       4272       3683          0          6       4135
```

One can argue that this is a waste of memory. On the other (conservative) side, one can argue that it is safest to pre-allocate the memory to reserve / ensure enough available memory to the file system should the system need it later. It depend on the use case, I guess.

### This method ###

The memory footprint of the file system is equivalent of the size of the current files in the file system, which means that free disk space does not consume memory. In some scenarios, this may be a far better approach in terms of resource cost. You may however very well overbook too much, so be careful to leave sufficient memory available for new files to be added. If the file system tries to use more memory than what’s currently available, your system will crash.

``` bash
             total       used       free     shared    buffers     cached
Mem:          7956       1179       6777          0          0       1001
```

## Difference in performance ##

The following measurements are far from being scientifically valid.

### Previous method ###

``` bash
[root@lab-a ~]# time dd if=/dev/zero of=/foobar bs=1M count=2000 ; time sync
2000+0 records in
2000+0 records out
2097152000 bytes (2.1 GB) copied, 2.45832 s, 853 MB/s

real	0m2.480s
user	0m0.003s
sys	0m2.002s

real	0m0.245s
user	0m0.000s
sys	0m0.037s
```

### This method ###

``` bash
[root@lab-e ~]# time dd if=/dev/zero of=/foobar bs=1M count=2000 ; time sync
2000+0 records in
2000+0 records out
2097152000 bytes (2.1 GB) copied, 0.823305 s, 2.5 GB/s

real	0m0.825s
user	0m0.002s
sys	0m0.821s

real	0m0.001s
user	0m0.000s
sys	0m0.002s
```
