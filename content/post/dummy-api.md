+++
Categories = ["Development", "API"]
Description = ""
Tags = ["Development", "API"]
date = "2015-05-02T21:42:21+02:00"
menu = "blog"
title = "Dummy API"

+++

The purpose of Dummy API to act as a performant, simple and flexible HTTP API to use when testing API gateway performance. The Dummy API will read the request headers and query parameters and generate the responses accordingly. Some examples are custom cache-control header, response status and response delays.

The following is a``GET`` request to host ``dummy-api.varnish-software.com`` and path ``/foo``, where the response should contain a 10 characters random string, 20 characters predictable random string, response status ``418`` and a ``cache-control`` header with the value ``max-age=2, s-maxage=3``. The response will be delivered with a 2 seconds delay before the first byte of the body, to mimic a slow web application:

    GET http://dummy-api.varnish-software.com/foo?random-content=10&predictable-content=20&response-status=418&body-delay=2&max-age=2&s-maxage=3
    
    HTTP/1.1 418 
    Cache-control: max-age=2, s-maxage=3
    Connection: close
    Content-Type: application/json
    Date: Sat, 02 May 2015 19:56:44 GMT
    Server: Dummy API
    Transfer-Encoding: chunked
    
    {
        "body-delay": 2, 
        "host": "dummy-api.varnish-software.com", 
        "max-age": 2, 
        "method": "GET", 
        "predictable-content": "fu4D0qBoQnap3NVA4PWy", 
        "random-content": "mqYA4IXTNG", 
        "response-status": 418, 
        "s-maxage": 3, 
        "uri": "/foo"
    }

The following is a ``POST`` request to ``dummy-api.varnish-software.com`` and path ``/someurl``, where the response status should be ``201`` and the ``cache-control`` header should be set to ``must-revalidate``:

    POST http://dummy-api.varnish-software.com/someurl?must-revalidate&response-status=201
    
    HTTP/1.1 201 Created
    Cache-control: must-revalidate
    Connection: close
    Content-Type: application/json
    Content-length: 135
    Date: Sat, 02 May 2015 19:58:04 GMT
    Server: Dummy API
    
    {
        "content-length": true, 
        "host": "dummy-api.varnish-software.com", 
        "method": "POST", 
        "must-revalidate": true, 
        "response-status": 201, 
        "uri": "/someurl"
    }

The buit in help text is available with the ``help`` request header or query parameter:

    GET http://dummy-api.varnish-software.com/?help

    HTTP/1.1 200 OK
    Connection: close
    Content-Type: text/plain
    Date: Sat, 02 May 2015 19:59:39 GMT
    Server: openresty
    Transfer-Encoding: chunked
    
    Dummy API
    =========
    
    The following request headers and query parameters will make an impact on the response.
    
    Delay
    -----
    header-delay = {float}           Delay to first header byte
    body-delay = {float}             Delay to first body byte
    
    Cache-control
    -------------
    max-age = {int}                  Set the response max-age value
    s-maxage = {int}                 Set the response s-maxage value
    must-revalidate                  Set must-revalidate
    public                           Set public
    private                          Set private
    no-store                         Set no-store
    no-cache                         Set no-cache
    no-transform                     Set no-transform
    
    Misc
    ----
    content-length                   Set the content-length header, otherwise chunked transfer encoding is used
    random-content = {int}           Add random string to the response of given length
    predictable-content = {int}      Add predictable string to the response of given length
    response-status = {int}          Set the response status

The Dummy API is written in Lua and is available for download at [Github](https://github.com/espebra/dummy-api). It will run on the [Openresty](http://openresty.org/) web application server.
