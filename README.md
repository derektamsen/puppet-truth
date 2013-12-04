# puppet-truth

## Overview
The puppet-truth module provides roles and tags for pre-hiera puppet (0.25.4).

## Requirements

- Ruby 1.8.6 installed on both the clients and server. (puppet-truth is rather old and may not work on 1.9)
- Facter installed on all clients.
- Puppet installed an running on both the master and clients.

## Installation
1. `pluginsync=true` needs to be set on the clients and master in `/etc/puppet/puppet.conf`.
2. In `/etc/puppet/fileserver.conf` define a private file path to store the host truth files. _The storage path needs to be 'truth_private' and the path needs to point to the truth module file path. You will want to allow your internal ip ranges only though._ Example:
```
[truth_private]
    path /etc/puppet/modules/truth/files/private/%d/%h
    allow 192.168.0.0/24
```
