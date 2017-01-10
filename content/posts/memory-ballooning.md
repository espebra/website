+++
Categories = ["sysadm"]
Description = ""
Tags = ["memory", "overhead", "virtualization", "xen", "kvm"]
date = "2012-09-24T16:58:32+01:00"
menu = "blog"
title = "KVM/Xen and libvirt: currentMemory, memory and ballooning. Where did my memory go?"
aliases = [
    "/post/memory-ballooning/",
    "/2012/09/kvmxen-and-libvirt-currentmemory-memory-and-ballooning-where-did-my-memory-go/"
]

+++


KVM and Xen provide a method to change the amount of memory in use by guests at runtime. The method is called memory ballooning [[1](http://www.linux-kvm.org/page/FAQ#Is_dynamic_memory_management_for_guests_supported.3F), [2](http://rwmj.wordpress.com/2010/07/17/virtio-balloon)], and it must be supported by the guest operating system to work.

In libvirt, memory allocation (and hence the ballooning capability) for a guest can be configured using the ``memory``, ``currentMemory`` and ``memballoon`` tags:

``` xml
<domain type='kvm'>
  [...]
  <memory unit='KiB'>16777216</memory>
  <currentMemory unit='KiB'>1048576</currentMemory>
  [...]
  <devices>
    <memballoon model='virtio'/>
  </devices>
</domain>
```

The guest can never use more memory than specified in the ``memory`` tag and it is the amount of memory the guest will use at boot time. The ``currentMemory`` tag, if set, should be less than or equal (default) to ``memory``. The guest will, when the balloon driver is loaded some time during the boot process, adjust itself to use the amount of memory specified by ``currentMemory``. The ``memballoon`` tag is being added automatically, so there is really no need to specify it.

The command line tool ``virsh`` can later be used on the host to see the current memory configuration for each guest:

``` bash
[root@host ~]# virsh dominfo guest
Id:             -
Name:           guest
UUID:           4f610a1f-7539-47cf-8299-9534500b340d
OS Type:        hvm
State:          shut off
CPU(s):         1
Max memory:     16777216 kB
Used memory:    1048576 kB
Persistent:     yes
Autostart:      disable
Managed save:   no
```

So far, so good. At this point it makes sense to set ``memory`` really high on all guests to ensure that we are able to reallocate memory on the fly for all our Linux guests. Doing this might not be a good idea.

Linux as a guest, even though it has a balloon driver, does not seem to behave like one would expect. When ``memory`` is set higher than ``currentMemory``, the guest operating system does not see (or use) the amount of memory that it should. Ideally, the value that libvirt reports as Used memory at the host should be visible inside the guest also.

The graphs below show different guests (RHEL6, SL6 and Ubuntu Precise) on KVM (SL6) and Xen (RHEL5). The Y-axis show the amount of memory visible inside the guest (as reported by ``free -m``), while the X-axis show the value of memory. The value of currentMemory is 1024M in all plots – which means that the guests should use 1024M of memory and that the graphs should stay flat out at 1024M, given zero overhead. The graphs show that this is not the reality.

![KVM, Ubuntu Precise, 1024 MB ram](/img/kvm-precise-1024.png)

![KVM, RHEL6, 1024 MB ram](/img/kvm-rhel6-1024.png)

![Xen, SL6, 1024 MB ram](/img/xen-sl6-1024.png)

![Xen, Ubuntu Precise, 1024 MB ram](/img/xen-precise-1024.png)

The graphs with KVM do not have values for 32G memory because the guests went ballistic and OOM-ed.
