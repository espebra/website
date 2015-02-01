+++
Categories = ["mikrotik"]
Description = ""
Tags = ["network"]
date = "2014-05-22T22:41:00+01:00"
menu = "blog"
title = "Altibox, TV- og datatrafikk over samme nettverkskabel"

+++

Altibox leverer en hjemmesentral hvor man henter ut TV-signal og internettilgang fra to (eller flere) forskjellige RJ45-porter. Som trådløs router har hjemmesentralen kun et minimum av funksjonalitet, og man skal ikke være en veldig avansert bruker før man vil rekonfigurere hjemmesentralen som en bridge og heller ha en egen trådløs router på baksiden. Dette gir også mening dersom boligen har flere etasjer, og hjemmesentralen ikke er kraftig nok til å levere god nok trådløs dekning.

Denne posten viser hvordan TV og datatrafikk kan sendes via èn nettverkskabel til et annet sted i boligen ved hjelp av to stk Mikrotik 951G-2HnD. RB951G-2HnD er en fleksibel trådløs router (2,4 GHz) med 5 stk 1 Gbps-porter beregnet på hjemmebruk. Utstyret kobles som skjemaet under viser.

![Diagram](/img/mikrotik-altibox.png)

Mikrotik A, konfigurasjon:

    /interface vlan add name=vlan-10 vlan-id=10 interface=ether2 disabled=no
    /interface bridge add name=br-vlan10 disabled=no
    /interface bridge port add interface="vlan-10" bridge="br-vlan10" disabled=no
    /interface ethernet set numbers=ether5-slave-local master-port=none
    /interface bridge port add interface="ether5-slave-local" bridge="br-vlan10" disabled=no

Mikrotik A, portoversikt:

    Port 1: Internett inn (datakabel fra Altibox hjemmesentral)
    Port 2: Trunk til Mikrotik B
    Port 3: Data
    Port 4: Data
    Port 5: TV inn (TV-kabel fra Altibox hjemmesentral)

Mikrotik B, konfigurasjon:

    /interface vlan add name=vlan-10 vlan-id=10 interface=ether2 disabled=no
    /interface bridge add name=br-vlan10 disabled=no
    /interface bridge port add interface="vlan-10" bridge="br-vlan10" disabled=no
    /interface ethernet set numbers=ether4-slave-local master-port=none
    /interface ethernet set numbers=ether5-slave-local master-port=none
    /interface bridge port add interface="ether4-slave-local" bridge="br-vlan10" disabled=no
    /interface bridge port add interface="ether5-slave-local" bridge="br-vlan10" disabled=no

I tillegg må Mikrotik B settes opp som en bridge.

Mikrotik B, portoversikt:

    Port 1: Data
    Port 2: Trunk til Mikrotik A
    Port 3: Data
    Port 4: TV ut
    Port 5: TV ut
