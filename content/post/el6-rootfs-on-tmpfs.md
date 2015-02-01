+++
Categories = ["netbooting"]
Description = ""
Tags = ["diskless", "el6", "ipxe", "linux", "netboot"]
date = "2012-04-31T21:44:19+01:00"
menu = "blog"
title = "CentOS/RHEL/SL 6: root filesystem on tmpfs"
aliases = [
    "/2012/04/centosrhelsl-6-root-filesystem-on-tmpfs"
]

+++



UPDATE: The patch below has been updated [here](/post/el6-rootfs-on-tmpfs-update).

There are several scenarios where conventional hard drives are not really needed. Examples are HPC cluster nodes, virtualization nodes, home theater streaming PCs, silent desktops, internet cafés and embedded systems. Hard drives tend to fail, they are slow, they consume power, they generate heat and noise, and they are quite expensive if you need/want something faster and more reliable than SATA.

This post will show how to run CentOS 6 directly from tmpfs backed by memory, without using the (standard) 512 MB writable overlay. The procedure should be similar for RHEL and Scientific Linux 6.

The resulting boot process will be:

* Boot a node off a PXE enabled DHCP server.
* Chainload into [iPXE](http://blog.braastad.org/?p=128).
* Download vmlinuz and a rather large initrd containing the entire filesystem over ftp/http(s). Try to avoid [TFTP](http://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol) when downloading the initrd because of its file size limitation and slow transfer speeds.
* Once downloaded, the kernel will start and the initrd will be mounted.
* The modified dracut scripts in the initrd will create a tmpfs partition in memory with the same size as your filesystem image included in the initrd.
* Your entire filesystem image will be copied to the tmpfs partition and attached to a loop device.
* This loop device will be used as the new root device, and the boot process continues as usual.

This is a screenshot from an ongoing boot process:
![Boot process](/img/centos6-from-tmpfs1.png)

Now to the procedure:

First, create a custom kickstart file. I've included the specialties below:

    bootloader --location=mbr --append="toram"
    clearpart --all
    firstboot --disabled
    install
    lang en_US.UTF-8
    network --bootproto dhcp --device eth0 --onboot yes
    part / --fstype=ext4 --size=2048
    reboot
    zerombr
    
    %packages
    patch
    
    %post
    cat > /etc/fstab << END 
    tmpfs      /         tmpfs   defaults         0 0
    devpts     /dev/pts  devpts  gid=5,mode=620   0 0
    tmpfs      /dev/shm  tmpfs   defaults         0 0
    proc       /proc     proc    defaults         0 0
    sysfs      /sys      sysfs   defaults         0 0
    END
    
    # The patch is base64 encoded to avoid having to escape it manually.
    cat > /root/dmsquash-live-root.base64 << EOF_patch
    MjFhMjIKPiBnZXRhcmcgdG9yYW0gJiYgdG9yYW09InllcyIKMTM0YzEzNSwxMzgKPCAgICAgZG9f
    bGl2ZV9mcm9tX2Jhc2VfbG9vcAotLS0KPiAgICAgIyBDcmVhdGUgb3ZlcmxheSBvbmx5IGlmIHRv
    cmFtIGlzIG5vdCBzZXQKPiAgICAgaWYgWyAteiAiJHRvcmFtIiBdIDsgdGhlbgo+ICAgICAgICAg
    ZG9fbGl2ZV9mcm9tX2Jhc2VfbG9vcAo+ICAgICBmaQoxNjNjMTY3LDIxMwo8ICAgICBkb19saXZl
    X2Zyb21fYmFzZV9sb29wCi0tLQo+ICAgICAjIENyZWF0ZSBvdmVybGF5IG9ubHkgaWYgdG9yYW0g
    aXMgbm90IHNldAo+ICAgICBpZiBbIC16ICIkdG9yYW0iIF0gOyB0aGVuCj4gICAgICAgICBkb19s
    aXZlX2Zyb21fYmFzZV9sb29wCj4gICAgIGZpCj4gZmkKPiAKPiAjIEkgdGhlIGtlcm5lbCBwYXJh
    bWV0ZXIgdG9yYW0gaXMgc2V0LCBjcmVhdGUgYSB0bXBmcyBkZXZpY2UgYW5kIGNvcHkgdGhlIAo+
    ICMgZmlsZXN5c3RlbSB0byBpdC4gQ29udGludWUgdGhlIGJvb3QgcHJvY2VzcyB3aXRoIHRoaXMg
    dG1wZnMgZGV2aWNlIGFzCj4gIyBhIHdyaXRhYmxlIHJvb3QgZGV2aWNlLgo+IGlmIFsgLW4gIiR0
    b3JhbSIgXSA7IHRoZW4KPiAgICAgYmxvY2tzPSQoIGJsb2NrZGV2IC0tZ2V0c3ogJEJBU0VfTE9P
    UERFViApCj4gCj4gICAgIGVjaG8gIkNyZWF0ZSB0bXBmcyAoJGJsb2NrcyBibG9ja3MpIGZvciB0
    aGUgcm9vdCBmaWxlc3lzdGVtLi4uIgo+ICAgICBta2RpciAtcCAvaW1hZ2UKPiAgICAgbW91bnQg
    LW4gLXQgdG1wZnMgLW8gbnJfYmxvY2tzPSRibG9ja3MgdG1wZnMgL2ltYWdlCj4gCj4gICAgIGVj
    aG8gIkNvcHkgZmlsZXN5c3RlbSBpbWFnZSB0byB0bXBmcy4uLiAodGhpcyBtYXkgdGFrZSBhIGZl
    dyBtaW51dGVzKSIKPiAgICAgZGQgaWY9JEJBU0VfTE9PUERFViBvZj0vaW1hZ2Uvcm9vdGZzLmlt
    Zwo+IAo+ICAgICBST09URlNfTE9PUERFVj0kKCBsb3NldHVwIC1mICkKPiAgICAgZWNobyAiQ3Jl
    YXRlIGxvb3AgZGV2aWNlIGZvciB0aGUgcm9vdCBmaWxlc3lzdGVtOiAkUk9PVEZTX0xPT1BERVYi
    Cj4gICAgIGxvc2V0dXAgJFJPT1RGU19MT09QREVWIC9pbWFnZS9yb290ZnMuaW1nCj4gCj4gICAg
    IGVjaG8gIkl0J3MgdGltZSB0byBjbGVhbiB1cC4uICIKPiAKPiAgICAgZWNobyAiID4gVW1vdW50
    aW5nIGltYWdlcyIKPiAgICAgdW1vdW50IC1sIC9pbWFnZQo+ICAgICB1bW91bnQgLWwgL2Rldi8u
    aW5pdHJhbWZzL2xpdmUKPiAKPiAgICAgZWNobyAiID4gRGV0YWNoICRPU01JTl9MT09QREVWIgo+
    ICAgICBsb3NldHVwIC1kICRPU01JTl9MT09QREVWCj4gCj4gICAgIGVjaG8gIiA+IERldGFjaCAk
    T1NNSU5fU1FVQVNIRURfTE9PUERFViIKPiAgICAgbG9zZXR1cCAtZCAkT1NNSU5fU1FVQVNIRURf
    TE9PUERFVgo+ICAgICAKPiAgICAgZWNobyAiID4gRGV0YWNoICRCQVNFX0xPT1BERVYiCj4gICAg
    IGxvc2V0dXAgLWQgJEJBU0VfTE9PUERFVgo+ICAgICAKPiAgICAgZWNobyAiID4gRGV0YWNoICRT
    UVVBU0hFRF9MT09QREVWIgo+ICAgICBsb3NldHVwIC1kICRTUVVBU0hFRF9MT09QREVWCj4gCj4g
    ICAgIGVjaG8gIlJvb3QgZmlsZXN5c3RlbSBpcyBub3cgb24gJFJPT1RGU19MT09QREVWLiIKPiAg
    ICAgZWNobwo+IAo+ICAgICBsbiAtcyAkUk9PVEZTX0xPT1BERVYgL2Rldi9yb290Cj4gICAgIHBy
    aW50ZiAnL2Jpbi9tb3VudCAtbyBydyAlcyAlc1xuJyAiJFJPT1RGU19MT09QREVWIiAiJE5FV1JP
    T1QiID4gL21vdW50LzAxLSQkLWxpdmUuc2gKPiAgICAgZXhpdCAwCjE2OWMyMTksMjIxCjwgICAg
    IGVjaG8gIjAgJCggYmxvY2tkZXYgLS1nZXRzeiAkQkFTRV9MT09QREVWICkgc25hcHNob3QgJEJB
    U0VfTE9PUERFViAkT1NNSU5fTE9PUERFViBwIDgiIHwgZG1zZXR1cCBjcmVhdGUgLS1yZWFkb25s
    eSBsaXZlLW9zaW1nLW1pbgotLS0KPiAgICAgaWYgWyAteiAiJHRvcmFtIiBdIDsgdGhlbgo+ICAg
    ICAgICAgZWNobyAiMCAkKCBibG9ja2RldiAtLWdldHN6ICRCQVNFX0xPT1BERVYgKSBzbmFwc2hv
    dCAkQkFTRV9MT09QREVWICRPU01JTl9MT09QREVWIHAgOCIgfCBkbXNldHVwIGNyZWF0ZSAtLXJl
    YWRvbmx5IGxpdmUtb3NpbWctbWluCj4gICAgIGZpCg==
    EOF_patch
    
    cat /root/dmsquash-live-root.base64 | base64 -d > /root/dmsquash-live-root.patch
    
    patch /usr/share/dracut/modules.d/90dmsquash-live/dmsquash-live-root /root/dmsquash-live-root.patch
    
    ls /lib/modules | while read kernel; do
      echo " > Update initramfs for kernel ${kernel}"
      initrdfile="/boot/initramfs-${kernel}.img"
    
      /sbin/dracut -f $initrdfile $kernel
    done
    %end
    
    %post --nochroot
    
    echo "Copy initramfs outside the chroot:"
    ls $INSTALL_ROOT/lib/modules | while read kernel; do
      src="$INSTALL_ROOT/boot/initramfs-${kernel}.img"
      dst="$LIVE_ROOT/isolinux/initrd0.img"
      echo " > $src -> $dst"
      cp -f $src $dst
    done
    %end

<b>Explaination:</b> The post script will apply a patch to <i>/usr/share/dracut/modules.d/90dmsquash-live/dmsquash-live-root</i> before regenerating the initramfs. This patch will add support for the 'toram' boot parameter. Then, the initramfs is being copied to the isolinux directory outside the filesystem image.

Second, use <i>livecd-creator</i> and <i>livecd-iso-to-pxeboot</i> from the <i>livecd-tools</i> package to convert the kickstart file into a bootable vmlinuz and initrd:

    $ sudo livecd-creator --config=centos6.ks fslabel=centos6
    $ sudo livecd-iso-to-pxeboot centos6.iso

The commands above will create <i>tftpboot/vmlinuz0</i> and <i>tftpboot/initrd0.img</i>. Put these files on your boot server and create a suitable PXE configuration. <i>livecd-iso-to-pxeboot</i> will create <i>tftpboot/pxelinux.cfg/default</i> which can be used as a template.

Now you are ready to boot one or multiple CentOS 6 in-memory instances over the network!

Another screenshot:
![losetup](/img/centos6-from-tmpfs-details.png)

Feature request [upstream](http://article.gmane.org/gmane.linux.kernel.initramfs/2588).
