+++
Categories = ["Development", "Golang"]
Description = ""
Tags = ["Development", "golang"]
date = "2016-01-08T21:11:44+01:00"
title = "Gofer - Simple notification IRC bot"

+++

[Gofer](https://github.com/espebra/gofer/) is an notification type of IRC bot which is simple to deploy and super easy to integrate with existing services. It serves two main purposes:

1. Process messages in IRC channels and [execute commands](https://github.com/espebra/gofer#command-execution) to trigger actions based on pre-defined patterns. A good use case is to look for messages matching ``#\d+`` (for example ``#1337``), look up the *title* and *status* in a issue tracker and print the information back in the IRC channel:

        user | So I just pushed a fix for #123.
        bot  | #123 [Open]: Server crash when foo (https://issue.tracker/tickets/123)

2. Relay notifications from other services onto IRC via the built in [HTTP API](https://github.com/espebra/gofer#http-api-interface). Good use cases for this are to let monitoring systems notify an IRC channel whenever some service status changes, and notify an IRC channel whenever a new ticket is created in the ticket system. Consider the following cURL command:

        $ curl -d "message=CRITICAL: http on somehost.example.com is unavailable - Socket timeout after 10 seconds" https://bot.example.com/channel/ops/privmsg

    It will produce the following privmsg (regular message) in the IRC channel *#ops*:

        bot | CRITICAL: http on somehost.example.com is unavailable - Socket timeout after 10 seconds

Being written in Go, gofer may be built and distributed as a statically linked binary on most platforms without dependencies.

