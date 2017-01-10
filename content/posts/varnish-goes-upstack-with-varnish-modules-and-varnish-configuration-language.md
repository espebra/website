+++
Categories = ["Development", "Varnish"]
Description = ""
Tags = ["Development", "Varnish"]
date = "2015-05-07T10:55:56+02:00"
menu = "blog"
title = "Varnish goes upstack with varnish modules and varnish configuration language"
aliases = [
    "/post/varnish-goes-upstack-with-varnish-modules-and-varnish-configuration-language/"
]

+++

*This post was first published at [High Scalability](http://highscalability.com/blog/2015/5/6/varnish-goes-upstack-with-varnish-modules-and-varnish-config.html).*

Varnish Software has just released Varnish API Engine, a high performance HTTP API Gateway which handles authentication, authorization and throttling all built on top of Varnish Cache. The Varnish API Engine can easily extend your current set of APIs with a uniform access control layer that has built in caching abilities for high volume read operations, and it provides real-time metrics.

Varnish API Engine is built using well known components like memcached, SQLite and most importantly Varnish Cache. The management API is written in Python. A core part of the product is written as an application on top of Varnish using VCL (Varnish Configuration Language) and VMODs (Varnish Modules) for extended functionality.

We would like to use this as an opportunity to show how you can create your own flexible yet still high performance applications in VCL with the help of VMODs.

## VMODs

VCL is the language used to configure Varnish Cache. When varnishd loads a VCL configuration file, it will convert it into C code, compile it and then load it dynamically. It is therefore possible to extend functionality of VCL by inlining C code directly into the VCL configuration file, but the preferred way to do it since Varnish Cache 3 has been to use Varnish Modules, or VMODs for short, instead.

The typical request flow in a stack containing Varnish Cache is:

![normal-workflow](/img/normal-workflow.png)

The client sends HTTP requests which are received and processed by Varnish Cache. Varnish Cache will decide to look up the requests in cache or not, and eventually it may fetch the content from the backend. This works very well, but we can do so much more.

The VCL language is designed for performance, and as such does not provide loops or external calls natively. VMODs, on the other hand, are free of these restrictions. This is great for flexibility, but places the responsibility for ensuring performance and avoiding delays on the VMOD code and behaviour.

The API Engine design illustrates how the powerful combination of VCL and custom VMODs can be used to build new applications. In Varnish API Engine, the request flow is:

![Fig showing workflow with sqlite and memcached VMODs](/img/vmod-workflow.png)

Each request is matched against a ruleset using the SQLite VMOD and a set of Memcached counters using the memcached VMOD. The request is denied if one of the checks fail, for example if authentication failed or if one of the request limits have been exceeded.

## Example application

The following example is a very simple version of some of the concepts used in the Varnish API Engine. We will create a small application written in VCL that will look up the requested URL in a database containing throttling rules and enforce them on a per IP basis.

Since testing and maintainability is crucial when developing an application, we will use Varnish's integrated testing tool: ``varnishtest``. Varnishtest is a powerful testing tool which is used to test all aspects of Varnish Cache. Varnishtest's simple interface means that developers and operation engineers can leverage it to test their VCL/VMOD configurations.

Varnishtest reads a file describing a set of mock servers, clients, and varnish instances. The clients perform requests that go via varnish, to the server. Expectations can be set on content, headers, HTTP response codes and more. With ``varnishtest`` we can quickly test our example application, and verify that our requests are passed or blocked as per the defined expectations.

First we need a database with our throttle rules. Using the sqlite3 command, we create the database in ``/tmp/rules.db3`` and add a couple of rules.

``` bash
$ sqlite3 /tmp/rules.db3 "CREATE TABLE t (rule text, path text);"
$ sqlite3 /tmp/rules.db3 "INSERT INTO t (rule, path) VALUES ('3r5', '/search');"
$ sqlite3 /tmp/rules.db3 "INSERT INTO t (rule, path) VALUES ('15r3600', '/login');"
```

These rules will allow 3 requests per 5 seconds to ``/search`` and 15 requests per hour to ``/login``. The idea is to enforce these rules on a per IP basis.

For the sake of simplicity, we’ll write the tests and VCL configuration in the same file, [throttle.vtc](/files/throttle.vtc). It is, however, possible to include separate VCL configuration files using include statements in the test files, to separate VCL configuration and the different tests.

The first line in the file is optionally used to set the name or the title of the test.

``` bash
varnishtest "Simple throttling with SQLite and Memcached"
```

Our test environment consists of one backend, called s1. We will first expect one request to a URL without a rule in the database.

``` bash
server s1 {
    rxreq
    expect req.url == "/"
    txresp
```

We then expect 4 requests to ``/search`` to arrive according to our following expectations. Note that the query parameters are slightly different, making all of these unique requests.
 
``` bash
    rxreq
    expect req.url == "/search?id=123&type=1"
    expect req.http.path == "/search"
    expect req.http.rule == "3r5"
    expect req.http.requests == "3"
    expect req.http.period == "5"
    expect req.http.counter == "1"
    txresp
  
    rxreq
    expect req.url == "/search?id=123&type=2"
    expect req.http.path == "/search"
    expect req.http.rule == "3r5"
    expect req.http.requests == "3"
    expect req.http.period == "5"
    expect req.http.counter == "2"
    txresp
  
    rxreq
    expect req.url == "/search?id=123&type=3"
    expect req.http.path == "/search"
    expect req.http.rule == "3r5"
    expect req.http.requests == "3"
    expect req.http.period == "5"
    expect req.http.counter == "3"
    txresp
  
    rxreq
    expect req.url == "/search?id=123&type=4"
    expect req.http.path == "/search"
    expect req.http.rule == "3r5"
    expect req.http.requests == "3"
    expect req.http.period == "5"
    expect req.http.counter == "1"
    txresp
} -start
```

Now it is time to write the mini-application in VCL. Our test environment consists of one varnish instance, called v1. Initially, the VCL version marker and the VMOD imports are added.

``` bash
varnish v1 -vcl+backend {
    vcl 4.0;
    import std;
    import sqlite3;
    import memcached;
```

VMODs are usually configured in ``vcl_init``, and this is true for sqlite3 and memcached as well. For sqlite3, we set the path to the database and the field delimiter to use on multi column results. The memcached VMOD can have a wide variety of configuration options supported by <a href="http://docs.libmemcached.org/libmemcached_configuration.html">libmemcached</a>.

``` bash
    sub vcl_init {
        sqlite3.open("/tmp/rules.db3", "|;");
        memcached.servers("--SERVER=localhost --BINARY-PROTOCOL");
    }
```

In ``vcl_recv``, the incoming HTTP requests are received. We start by extracting the request path without query parameters and potential dangerous characters. This is important since the path will be part of the SQL query later. The following regex will match ``req.url`` from the beginning of the line up until any of the characters ? &amp; ;  “  ‘ or whitespace.

``` bash
    sub vcl_recv {
        set req.http.path = regsub(req.url, {"^([^?&;"' ]+).*"}, "\1");
```

The use of ``{" "}`` in the regular expression enables handling of the " character in the regular expression rule. The path we just extracted is used when the rule is looked up in the database. The response, if any, is stored in ``req.http.rule``.

``` bash
        set req.http.rule = sqlite3.exec("SELECT rule FROM t WHERE path='" + req.http.path + "' LIMIT 1");
```

If we get a response, it will be on the format ``RnT``, where ``R`` is the amount of requests allowed over a period of ``T`` seconds. Since this is a string, we need to apply more regex to separate those.

``` bash
        set req.http.requests = regsub(req.http.rule, "^([0-9]+)r.*$", "\1");
        set req.http.period = regsub(req.http.rule, "^[0-9]+r([0-9]+)$", "\1");
```

We do throttling on this request only if we got proper values from the previous regex filters.

``` bash
        if (req.http.requests != "" && req.http.period != "") {
```

Increment or create a Memcached counter unique for this ``client.ip`` and path with the value 1. The expiry time we specify is equal to the period in the throttle rule set in the database. This way, the throttle rules can be flexible regarding time period. The return value is the new value of the counter, which corresponds to the amount of requests this ``client.ip`` has done this path in the current time period.

``` bash
           set req.http.counter = memcached.incr_set(
               req.http.path + "-" + client.ip, 1, 1, std.integer(req.http.period, 0));
```

Check if the counter is higher than the limit set in the database. If it is, then abort the request here with a ``429`` response code.

``` bash
            if (std.integer(req.http.counter, 0) > std.integer(req.http.requests, 0)) {
                 return (synth(429, "Too many requests"));
            }
        }
    }
```

In ``vcl_deliver`` we set response headers showing the throttle limit and status for each request which might be helpful for the consumers.

``` bash
    sub vcl_deliver {
        if (req.http.requests && req.http.counter && req.http.period) {
            set resp.http.X-RateLimit-Limit = req.http.requests;
            set resp.http.X-RateLimit-Counter = req.http.counter;
            set resp.http.X-RateLimit-Period = req.http.period;
        }
    }
```

Errors will get the same headers set in ``vcl_synth``.

``` bash
    sub vcl_synth {
        if (req.http.requests && req.http.counter && req.http.period) {
            set resp.http.X-RateLimit-Limit = req.http.requests;
            set resp.http.X-RateLimit-Counter = req.http.counter;
            set resp.http.X-RateLimit-Period = req.http.period;
        }
    }
} -start
```

The configuration is complete, and it is time to add some clients to verify that the configuration is correct. First we send a request that we expect to be unthrottled, meaning that there are no throttle rules in the database for this URL.

``` bash
client c1 {
    txreq -url "/"
    rxresp
    expect resp.status == 200
    expect resp.http.X-RateLimit-Limit == <undef>
    expect resp.http.X-RateLimit-Counter == <undef>
    expect resp.http.X-RateLimit-Period == <undef>
} -run
```

The next client sends requests to a URL that we know is a match in the throttle database, and we expect the rate-limit headers to be set. The throttle rule for ``/search`` is ``3r5``, which means that the three first requests within a 5 second period should succeed (with return code ``200``) while the fourth request should be throttled (with return code ``429``). 

``` bash
client c2 {
    txreq -url "/search?id=123&type=1"
    rxresp
    expect resp.status == 200
    expect resp.http.X-RateLimit-Limit == "3"
    expect resp.http.X-RateLimit-Counter == "1"
    expect resp.http.X-RateLimit-Period == "5"
  
    txreq -url "/search?id=123&type=2"
    rxresp
    expect resp.status == 200
    expect resp.http.X-RateLimit-Limit == "3"
    expect resp.http.X-RateLimit-Counter == "2"
    expect resp.http.X-RateLimit-Period == "5"
  
    txreq -url "/search?id=123&type=3"
    rxresp
    expect resp.status == 200
    expect resp.http.X-RateLimit-Limit == "3"
    expect resp.http.X-RateLimit-Counter == "3"
    expect resp.http.X-RateLimit-Period == "5"
  
    txreq -url "/search?id=123&type=4"
    rxresp
    expect resp.status == 429
    expect resp.http.X-RateLimit-Limit == "3"
    expect resp.http.X-RateLimit-Counter == "4"
    expect resp.http.X-RateLimit-Period == "5"
} -run
```

At this point, we know that requests are being throttled. To verify that new requests are allowed after the time limit is up, we add a delay here before we send the next and last request. This request should succeed since we are in a new throttle window.

``` bash
delay 5;
 
client c3 {
   txreq -url "/search?id=123&type=4"
   rxresp
   expect resp.status == 200
   expect resp.http.X-RateLimit-Limit == "3"
   expect resp.http.X-RateLimit-Counter == "1"
   expect resp.http.X-RateLimit-Period == "5"
} -run
```

To execute the test file, make sure the memcached service is running locally and execute:

``` bash
$ varnishtest example.vtc
#     top  TEST example.vtc passed (6.533)
```

Add ``-v`` for verbose mode to get more information from the test run.

Requests to our application in the example will receive the following response headers. The first is a request that has been allowed, and the second is a request that has been throttled.

``` http
$ curl -iI http://localhost/search
HTTP/1.1 200 OK
Age: 6
Content-Length: 936
X-RateLimit-Counter: 1
X-RateLimit-Limit: 3
X-RateLimit-Period: 5
X-Varnish: 32770 3
Via: 1.1 varnish-plus-v4

$ curl -iI http://localhost/search
HTTP/1.1 429 Too many requests
Content-Length: 273
X-RateLimit-Counter: 4
X-RateLimit-Limit: 3
X-RateLimit-Period: 5
X-Varnish: 32774
Via: 1.1 varnish-plus-v4
```

The complete [throttle.vtc](/files/throttle.vtc) file outputs timestamp information before and after VMOD processing, to give us some data on the overhead introduced by the Memcached and SQLite queries. Running 60 requests in varnishtest on a local vm with Memcached running locally returned the following timings pr operation (in ms):

* SQLite SELECT, max: 0.32, median: 0.08, average: 0.115
* Memcached incr_set(), max: 1.23, median: 0.27, average: 0.29

These are by no means scientific results, but hints to performance that should for most scenarios prove to be fast enough. Performance is also about the ability to scale horizontally. The simple example provided in this article will scale horizontally with global counters in a pool of Memcached instances if needed.

![Fig showing horizontally scaled setup](/img/horizontal-scaling.png)

## Further reading

There are a number of VMODs available, and the [VMODs Directory](https://www.varnish-cache.org/VMODs) is a good starting point. Some highlights from the directory are VMODs for cURL usage, Redis, Digest functions and various authentication modules.

Varnish Plus, the fully supported commercial edition of Varnish Cache, is bundled with a set of high quality, support backed VMODs. For the open source edition, you can download and compile the VMODs you require manually.

Varnish API Engine is more than VCL and VMODs. It also packs features such as key authentication, a centralized REST API for management, administration interface and real time statistics. For more information about Varnish API Engine, please contact [Varnish Software](https://www.varnish-software.com/).

