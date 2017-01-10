+++
Categories = ["netbooting"]
Description = ""
Tags = ["ipxe", "kvm", "virtualization"]
date = "2011-11-02T22:29:50+01:00"
title = "KVM with iPXE in RHEL6"
aliases = [
    "/post/kvm-with-ipxe-in-rhel6/"
]

+++

A while ago I discovered the amazing [iPXE](http://ipxe.org) project. It is a complete PXE implementation with lots of nifty features, based on the [gPXE](http://etherboot.org/) project. Redhat ships the gPXE firmware for qemu and KVM, and you might want to use iPXE instead as the iPXE project currently seems to be more active. The major features (copied from [ipxe.org](http://ipxe.org)):

* boot from a web server via HTTP
* boot from an iSCSI SAN
* boot from a Fibre Channel SAN via FCoE
* boot from an AoE SAN
* boot from a wireless network
* boot from a wide-area network
* boot from an Infiniband network
* control the boot process with a script

First, download the source code:

``` bash
espen@luft:~$ mkdir ~/git
espen@luft:~$ cd ~/git
espen@luft:~/git$ git clone git://git.ipxe.org/ipxe.git
Cloning into ipxe...
remote: Counting objects: 33376, done.
remote: Compressing objects: 100% (9193/9193), done.
remote: Total 33376 (delta 24642), reused 30782 (delta 22666)
Receiving objects: 100% (33376/33376), 8.02 MiB | 1.94 MiB/s, done.
Resolving deltas: 100% (24642/24642), done.
espen@luft:~/git$ cd ipxe/
espen@luft:~/git/ipxe$
```

Then change the general configuration file (<em>src/config/general.h</em>) to suit your needs. Use the <strong>#define</strong> and <strong>#undef</strong> to activate and deactivate various features such as VLAN support, DHCP support, etc. Below is a small part of [the header file](https://github.com/ipxe/ipxe/blob/master/src/config/general.h) for you to see.

``` bash
[...]
#define IWMGMT_CMD   /* Wireless interface management commands */
#define FCMGMT_CMD   /* Fibre Channel management commands */
#define ROUTE_CMD    /* Routing table management commands */
#define IMAGE_CMD    /* Image management commands */
#define DHCP_CMD     /* DHCP management commands */
#define SANBOOT_CMD  /* SAN boot commands */
#define LOGIN_CMD    /* Login command */
#undef  TIME_CMD     /* Time commands */
#undef  DIGEST_CMD   /* Image crypto digest commands */
#undef  LOTEST_CMD   /* Loopback testing commands */
#undef  VLAN_CMD     /* VLAN commands */
#undef  PXE_CMD      /* PXE commands */
#undef  REBOOT_CMD   /* Reboot command */
[...]
```

Now it's time compile the firmware.

``` bash
espen@luft:~/git/ipxe$ cd src/
espen@luft:~/git/ipxe/src$ make bin/virtio-net.rom
  [DEPS] arch/i386/drivers/net/undirom.c
  [DEPS] arch/i386/drivers/net/undipreload.c
  [DEPS] arch/i386/drivers/net/undionly.c
  [DEPS] arch/i386/drivers/net/undinet.c
[...]
  [BIN] bin/virtio-net.rom.bin
  [ZINFO] bin/virtio-net.rom.zinfo
  [ZBIN] bin/virtio-net.rom.zbin
  [FINISH] bin/virtio-net.rom
[...]
espen@luft:~/git/ipxe/src$
```

The firmware compiled successfully, and it is ready to use. Log onto the RHEL 6 node, and verify that you have installed the package <strong>gpxe-roms-qemu</strong> (<strong>qemu-kvm</strong> currently depends on <strong>gpxe-roms-qemu</strong>). The directory <em>/usr/share/gpxe/</em> contains the gPXE boot roms from this package.

To use your custom iPXE boot firmware instead, you can build a new rpm package that contains the new rom - or you can simply replace <em>/usr/share/gpxe/virtio-net.rom</em> [gPXE] with your <em>~/git/ipxe/src/bin/virtio-net.rom</em> [iPXE]. As least you will have iPXE boot firmware until the <strong>qemu-roms-qemu</strong> package is updated ;)

Make sure that your virtual machines are using the [virtio](http://wiki.libvirt.org/page/Virtio) network device driver, and you are all set:

``` xml
[...]
<interface type='bridge'>
  [...]
  <model type='virtio'/>
</interface>
[...]
```

Your virtual machines will now be booted using the iPXE boot firmware. Have a look at the [iPXE scripting documentation](http://ipxe.org/scripting) for more inspiration!

