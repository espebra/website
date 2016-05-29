+++
Categories = ["Development", "GoLang"]
Description = ""
Tags = ["Development", "golang"]
date = "2016-05-29T20:40:48+02:00"
title = "Filebin upgrade"

+++

[https://filebin.net](https://filebin.net) is a public and free file upload/sharing service. Its main design principle is to be incredibly simple to use.

It has been in production for several years, and has more or less been unmodified until now. Today it has been upgraded in several ways, and this post aims to elaborate on some of the changes.

## Complete rewrite

[The previous version of Filebin](https://github.com/espebra/filebin/tree/python) was written in Python and kept meta data in [MongoDB](https://mongodb.com). For a number of reasons, Filebin has been completely rewritten in Go. It does no longer depend on any database except the local filesystem.

Some of the most visible changes are:

* **Tags are now called bins**

    The concept of *tags* was always difficult to explain and confusing for new users. Hopefully *bins* will be easier to understand. At least it is related to the domain and application name.

* **Bins are private only**

    Earlier, tags could (optionally) be promoted publicly by being shown in a public list, for example to be picked up by crawlers. To simplify and avoid abuse, this feature is removed. From now on, all bins are private and it is necessary to know the URL to get access. The URL has to be shared using some other mechanism outside Filebin, such as email or instant messaging.

* **No moderation**

    The *report for moderation* functionality is gone. As a replacement, files can be deleted by any user knowing the URL to the bin. This is potentially controversional and problematic. The idea is to let users themselves delete malicious or illegal files uploaded by other users instead of going through a moderation process.

    The potential downside is obviously that bad internet citizens that know the URL to a perfectly valid bin have access to delete it, and may do so just for the fun of it.

    This open permission model is a bit experimental, and will have to be reconsidered as time goes. Feedback and suggestions are appreciated.

* **Album view**

    Bins with images now have an *album view* with larger versions of the images. This makes it convenient to view multiple images.

## New software stack

The infrastructure, bandwidth and hardware needed to run [filebin.net](https://filebin.net) is sponsored by [Redpill Linpro](http://redpill-linpro.com/), the leading provider of professional Open Source services and products in the Nordic region.

As part of todays upgrade, [filebin.net](https://filebin.net) has been migrated into their IaaS cloud which is based on [OpenStack](https://www.openstack.org/) and [Ceph](http://ceph.com/), runs on modern hardware and spans multiple locations.

* **Encrypted communications**

    Client-server communication is now encrypted using HTTPS/TLS with certificates from [Let's encrypt](https://letsencrypt.org/). The TLS proxy [Hitch](https://hitch-tls.org) is used to take care of the TLS handling.

* **HTTP caching**

    [Varnish Cache](https://varnish-cache.org) is now running in front of Filebin to boost performance.

The source code of Filebin is available at [Github](https://github.com/espebra/filebin). Bugs are reported and tracked in [Github issues](https://github.com/espebra/filebin/issues).

Feel free to reach out for feedback and suggestions by email to espebra(a)ifi.uio.no, or by leaving a comment to this blog post.
