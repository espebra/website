+++
Categories = ["mikrotik"]
Description = ""
Tags = ["network"]
date = "2014-08-30T20:48:00+01:00"
menu = "blog"
title = "Remote console on HP ProLiant MicroServer G7 N54L"
aliases = [
    "/post/remote-console-on-hp-proliant-microserver-g7-n54l/"
]

+++

I bought the [HP ProLiant MicroServer G7 N54L](http://www8.hp.com/us/en/products/proliant-servers/product-detail.html?oid=6280786) a while ago. I threw in a [HP MicroServer Remote Access Card Kit](http://www8.hp.com/us/en/products/oas/product-detail.html?oid=4275612) to get remote console and power management. While the power management, web UI and CLI (over ssh) works fine out of the box, the remote console (KVM) does not. What happens is that the KVM client shows the following ``Out of range`` message:

![Out of range](/img/outofrange.png)

To fix this, go into the BIOS. Navigate to Advanced, PCI Express Configuration and Embedded VGA Control like this:

![BIOS 1](/img/bios1.png)
![BIOS 2](/img/bios2.png)

Flip from ``Always enabled`` (default) to ``Auto Detect``. Save and quit. Then, make sure that your monitor is connected to the VGA port on the RAC instead of the embedded VGA port.

