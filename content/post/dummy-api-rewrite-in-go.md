+++
Categories = ["Development", "GoLang"]
Description = ""
Tags = ["Development", "API", "golang"]
date = "2015-05-16T19:48:47+02:00"
menu = "blog"
title = "Dummy API, Go rewrite"

+++

Dummy API was [originally]({{< ref "post/dummy-api.md" >}}) written in Lua for running on top of [OpenResty](https://www.openresty.org/). Reasons were high performance and simplicity. The most common Linux distributions do not provide packages for OpenResty in their repositories, which means that it has to be installed from source. This is straight forward, but it adds up - both in time required and extra build dependencies. 

The purpose of Dummy API is to be that web application that can be rapidly installed and started when it is necessary to test API managers and web caches with a proper web application. The installation should be as simple and quick as possible.

I turned to [Go](https://golang.org/) and its [http server](https://golang.org/pkg/net/http/), and reimplemented the Dummy API. What is really appealing it that is possible to compile an entire web application including all dependencies into one binary file. It means that the Dummy API and the web server can be compiled and distributed as one executable file:

    $ sudo yum install golang
    $ go build dummy-api.go
    $ chmod +x dummy-api
    $ ./dummy-api -host=0.0.0.0 -port=8080

It is possible to cross compile to various architectures and platforms. 

I have compiled and pushed the binary version for ``Linux`` on ``x86_64`` to the repository. The result is that the installation steps have been narrowed down to:

    $ wget https://github.com/espebra/dummy-api/raw/master/dummy-api
    $ chmod +x dummy-api
    $ ./dummy-api

By default, it will bind to ``127.0.0.1:1337``. ``./dummy-api -help`` shows the usage guide:

    Usage of ./dummy-api:
      -host="127.0.0.1": Listen host
      -maxheaderbytes=1048576: Max header bytes.
      -port=1337: Listen port
      -readtimeout=10: Read timeout in seconds
      -writetimeout=10: Write timeout in seconds

The usage guide for web clients is shown with the ``help`` query parameter:

    GET http://host/?help

    Dummy API
    =========
    
    The following request headers and query parameters will make an impact on the response.
    
    Delay
    -----
    header-delay = {int}         Delay to first header byte in ms.
    body-delay = {int}           Delay to first body byte in ms.
    
    Cache-control
    -------------
    max-age = {int}              Set the cache-control max-age value.
    s-maxage = {int}             Set the cache-control s-maxage value.
    must-revalidate              Set cache-control must-revalidate.
    public                       Set cache-control public.
    private                      Set cache-control private.
    no-store                     Set cache-control no-store.
    no-cache                     Set cache-control no-cache.
    no-transform                 Set cache-control no-transform.
    
    Misc
    ----
    content-length               Set the content-length header, otherwise chunked
                                 transfer encoding is used.
    random-content = {int}       Add random string to the response of given length.
    predictable-content = {int}  Add predictable string to the response of given
                                 length.
    connection=close             Add connection=close to the response headers.
    response-status = {int}      Set the response status.

The Go version is available in [master](https://github.com/espebra/dummy-api/), while the Lua version is available in the [Lua branch](https://github.com/espebra/dummy-api/tree/lua). Remember to run it with an unprivileged user. 

