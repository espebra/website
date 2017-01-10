+++
Categories = ["monitoring"]
date = "2010-08-16T20:15:00+01:00"
title = "munincollector-ng"
Tags = ["munin"]
menu = "blog"
aliases = [
    "/2010/08/munincollector-ng",
    "/blog/2010/08/munincollector-ng/",
    "/post/munincollector-ng/"
]

+++

Munincollector-ng is a perl script that collects graphs from multiple [munin](http://munin-monitoring.org) installations to display them in one page. A scenario where this is helpful is when you have (too) many munin clients on (too) many munin masters, and you want to look through some of the graphs - i.e. the <em>Disk usage in percent</em> (aka <em>df</em>) plugin - without spending/wasting too much time browsing through the less important graphs.

![Munincollector](/img/munincollector.png)

It consists of one perl script and one configuration file. It is being executed regularly by cron. At each run, it iterates through the configuration file; downloads the graphs to a local directory and generates an html file.

Below is some example configuration that will gather the <em>week</em> and <em>month</em> graphs from the <em>df</em> plugin from four separate munin masters (three without authentication and one with authentication). The graphs will be downloaded to <em>/var/www/munincollector-ng/</em>:

``` bash
# General configuration
graph.plugin df
graph.type week month
graph.log /var/log/munincollector-ng.log
graph.dir /var/www/munincollector-ng

# Configuration per munin master you want to collect graphs from.
# The format is: <id>.<option> <value>

# Three munin installations with no authentication
uio.url http://munin.ping.uio.no
foo.url http://foo.com/munin/
bar.url http://bar.com/munin/

# One munin master that requires authentication
baz.url http://baz.com/munin/
baz.realm Munin
baz.username user1
baz.password pass1
baz.netloc baz.com:80
```

An example cron job that will execute the script once per day (make sure <em>user</em> have write permissions in <em>/var/www/munincollector-ng/</em>):

``` cron
8 8 * * * user /usr/local/bin/munincollector-ng -c /etc/munincollector-ng/example.conf
```

The script is available from [Github](https://github.com/espebra/munincollector-ng).

PS: Put the <em>logo.png</em> and <em>style.css</em> from your <em>/etc/munin/templates/</em> directory into <em>/var/www/munincollector-ng/</em> to make it look a bit nicer.

